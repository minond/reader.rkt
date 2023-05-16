import { Component, html } from "/public/preact.js";
import { SpinningRing } from "/public/component.js";
import Modal from "/public/modal.js";
import { debounce } from "/public/common.js";

const INPUT_IDLE = 0;
const INPUT_LOADING = 1;
const INPUT_ERROR = 2;

export default class AddItem extends Component {
  componentWillMount() {
    this.modalController = Modal.render(AddItemForm).controller;
  }

  render() {
    // return html`<a onClick=${() => this.modalController.show()}>Add feed</a>`;
    return html`<a href="/feeds/new">Add feed</a>`;
  }
}

class AddItemForm extends Component {
  constructor() {
    super();

    this.state = {
      inputState: INPUT_IDLE,
      suggestions: null,
      value: "",
    };

    this.inputRef = { current: null };
    this.requestAbortController = null;
    this.handleEscapeBound = this.handleEscape.bind(this);
    this.fetchSuggestionsDebounced = debounce(
      this.fetchSuggestions.bind(this),
      500
    );
  }

  componentDidMount() {
    this.focusOnInput();
    document.body.classList.add("no-scroll");
    document.addEventListener("keydown", this.handleEscapeBound, false);
  }

  componentWillUnmount() {
    document.body.classList.remove("no-scroll");
    document.removeEventListener("keydown", this.handleEscapeBound, false);
  }

  handleInput(ev) {
    const newValue = ev.target.value || "";
    if (newValue.trim() === this.state.value.trim()) {
      return;
    }

    this.setState(
      { value: newValue, inputState: INPUT_LOADING },
      this.fetchSuggestionsDebounced
    );
    this.cancelFetchSuggestions();
  }

  handleEscape(ev) {
    switch (ev.keyCode) {
      case 27:
        this.cancelFetchSuggestions();
        this.setState({ value: "", suggestions: null, inputState: INPUT_IDLE });

        if (!ev.target.value) {
          this.props.controller.hide();
        } else {
          ev.target.value = "";
        }

        ev.preventDefault();
        return false;
    }
  }

  cancelFetchSuggestions() {
    if (this.requestAbortController) {
      this.requestAbortController.abort();
    }
  }

  fetchSuggestions() {
    const input = this.state.value.trim();
    if (!input) {
      return;
    }

    this.requestAbortController = new AbortController();

    const url = `/suggestions?url=${encodeURIComponent(input)}`;
    this.setState({ inputState: INPUT_LOADING }, () => {
      fetch(url, { signal: this.requestAbortController.signal })
        .then((res) => res.json())
        .then((body) => body.suggestions)
        .then((suggestions) =>
          this.setState({
            inputState: INPUT_IDLE,
            suggestions,
          })
        )
        .catch((err) => {
          if (err.code === err.ABORT_ERR) {
            return;
          }

          console.error("error making suggestions", err);
          this.setState({ suggestions: null, inputState: INPUT_ERROR });
        });
    });
  }

  focusOnInput() {
    this.inputRef?.current?.base?.querySelector("input")?.focus();
  }

  render() {
    const formClasses = ["add-item-form", "input-container-parent"];
    if (this.state.inputState === INPUT_LOADING) {
      formClasses.push("loading");
    }

    return html`<div
      class=${formClasses.join(" ")}
      onClick=${(ev) => ev.stopPropagation()}
    >
      <${Input}
        onInput=${(ev) => this.handleInput(ev)}
        value=${this.state.value}
        ref=${this.inputRef}
      />
      <${Suggestions}
        suggestions=${this.state.suggestions}
        inputState=${this.state.inputState}
        value=${this.state.value}
        onSuggestionClick=${(args) => console.log(args)}
      />
    </div>`;
  }
}

const Input = ({ value, ref, onInput, onKeyPress }) =>
  html`<div class="input-container">
    <input
      autocapitalize="off"
      autocomplete="off"
      autocorrect="off"
      ref=${ref}
      name="value"
      onInput=${onInput}
      onKeyPress=${onKeyPress}
      placeholder="Search by name or RSS link"
      spellcheck="false"
      type="text"
      value=${value}
    />
    <${SpinningRing} size="30" />
  </div>`;

const Suggestions = ({ suggestions, inputState, value, onSuggestionClick }) => {
  if (
    (!!suggestions && !suggestions.length && inputState !== INPUT_LOADING) ||
    inputState === INPUT_ERROR
  ) {
    return html`<div class="suggestions">
      <div class="suggestion">
        <div class="suggestion-message">
          Nothing found for <b>“${value}”</b>. Please try again.
        </div>
      </div>
    </div>`;
  } else if (!!suggestions && !!suggestions.length) {
    return html`<div class="suggestions">
      ${suggestions.map(
        (suggestion) =>
          html`<${Suggestion} ...${suggestion} onClick=${onSuggestionClick} />`
      )}
    </div>`;
  } else {
    return null;
  }
};

const Suggestion = ({ kind, title, url, onClick }) =>
  html`<div class="suggestion" onClick=${() => onClick({ kind, title, url })}>
    <div class="suggestion-title">${title}</div>
    <div class="suggestion-url">${url}</div>
    <div class="suggestion-kind">
      <div class="suggestion-kind-container">${kind}</div>
    </div>
  </div>`;
