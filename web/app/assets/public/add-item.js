import { Component, html, render } from "/public/preact.js";
import { SpinningRing } from "/public/component.js";
import { debounce } from "/public/common.js";

const INPUT_IDLE = 0;
const INPUT_LOADING = 1;
const INPUT_ERROR = 2;

const SHOW_OFF = 0;
const SHOW_ON = 1;
const SHOW_HIDING = 2;

export default class AddItem extends Component {
  constructor() {
    super();

    this.state = {
      showState: SHOW_OFF,
    };

    this.modalController = {};
    this.modalContainer = document.body.appendChild(
      document.createElement("div")
    );
    this.modalContainer.dataset.modalContainer = true;
  }

  componentWillMount() {
    render(
      html`<${Modal}
        controller=${this.modalController}
        onClose=${() => this.hideModal()}
      />`,
      this.modalContainer
    );
  }

  hideModal() {
    this.modalController.hide();
  }

  showModal() {
    this.modalController.show();
  }

  render() {
    return html`<a href="#" onClick=${() => this.showModal()}>Add feed</a>`;
  }
}

class Modal extends Component {
  constructor() {
    super();

    this.state = {
      inputState: INPUT_IDLE,
      showState: SHOW_OFF,
      suggestions: null,
      value: "",
    };

    this.requestAbortController = null;
    this.fetchSuggestionsDebounced = debounce(
      this.fetchSuggestions.bind(this),
      500
    );
  }

  componentWillMount() {
    this.props.controller.show = () => {
      if (this.state.showState !== SHOW_HIDING) {
        this.setState({ showState: SHOW_ON });
      }
    };

    this.props.controller.hide = () => {
      this.setState({ showState: SHOW_HIDING }, () =>
        setTimeout(() => this.setState({ showState: SHOW_OFF }), 100)
      );
    };
  }

  handleFormSubmit(ev) {
    ev.preventDefault();
    return false;
  }

  handleInput(ev) {
    const newValue = ev.target.value;
    if (newValue.trim() === this.state.value.trim()) {
      return;
    }

    this.setState(
      { value: newValue, inputState: INPUT_LOADING },
      this.fetchSuggestionsDebounced
    );
    this.cancelFetchSuggestions();
  }

  cancelFetchSuggestions() {
    if (this.requestAbortController) {
      this.requestAbortController.abort();
    }
  }

  fetchSuggestions() {
    this.requestAbortController = new AbortController();

    const url = `/suggestions?url=${encodeURIComponent(
      this.state.value.trim()
    )}`;
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
          this.setState({ suggestions: [], inputState: INPUT_ERROR });
        });
    });
  }

  render() {
    if (this.state.showState === SHOW_OFF) {
      return null;
    }

    const formClasses = ["add-item-form"];
    const inputContainerClasses = ["input-container"];
    if (this.state.inputState === INPUT_LOADING) {
      formClasses.push("loading");
      inputContainerClasses.push("loading");
    }

    const styles = {};
    if (this.state.showState === SHOW_HIDING) {
      styles.opacity = 0;
    }

    let suggestions = null;
    if (
      (!!this.state.suggestions &&
        !this.state.suggestions.length &&
        this.state.inputState !== INPUT_LOADING) ||
      this.state.inputState === INPUT_ERROR
    ) {
      suggestions = html`<div class="suggestions">
        <div class="suggestion">
          <div class="suggestion-message">
            Nothing found for <b>“${this.state.value.trim()}”</b>. Please try
            again.
          </div>
        </div>
      </div>`;
    } else if (!!this.state.suggestions && !!this.state.suggestions.length) {
      suggestions = html`<div class="suggestions">
        ${this.state.suggestions.map(
          (suggestion) => html`<${Suggestion} ...${suggestion} />`
        )}
      </div>`;
    }

    return html`<div
      class="backdrop"
      style=${styles}
      onClick=${this.props.onClose}
    >
      <form
        class=${formClasses.join(" ")}
        onSubmit=${(ev) => this.handleFormSubmit(ev)}
        onClick=${(ev) => ev.stopPropagation()}
      >
        <div class="add-item-form-content">
          <div class=${inputContainerClasses.join(" ")}>
            <input
              autocapitalize="off"
              autocomplete="off"
              autocorrect="off"
              autofocus="yes"
              name="value"
              onInput=${(ev) => this.handleInput(ev)}
              placeholder="Search by name or RSS link"
              spellcheck="false"
              type="text"
              value=${this.state.value}
            />
            <${SpinningRing} size="30" />
          </div>
          ${suggestions}
        </div>
      </form>
    </div> `;
  }
}

const Suggestion = ({ kind, title, url }) =>
  html`<div class="suggestion">
    <div class="suggestion-title">${title}</div>
    <div class="suggestion-url">${url}</div>
    <div class="suggestion-kind">
      <div class="suggestion-kind-container">${kind}</div>
    </div>
  </div>`;
