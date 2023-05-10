import { Component, html, render } from "/public/preact.js";
import { SpinningRing } from "/public/component.js";
import { debounce } from "/public/common.js";

const IDLE = 0;
const LOADING = 1;
const ERROR = 2;

export default class AddItem extends Component {
  constructor() {
    super();

    this.state = {
      state: IDLE,
      suggestions: [],
      value: "",
    };

    this.controller = null;
    this.fetchSuggestionsDebounced = debounce(
      this.fetchSuggestions.bind(this),
      500
    );
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

    this.setState({ value: newValue }, this.fetchSuggestionsDebounced);
    this.cancelFetchSuggestions();
  }

  cancelFetchSuggestions() {
    if (this.controller) {
      this.controller.abort();
    }
  }

  fetchSuggestions() {
    this.controller = new AbortController();

    const url = `/suggestions?url=${encodeURIComponent(
      this.state.value.trim()
    )}`;
    this.setState({ state: LOADING }, () => {
      fetch(url, { signal: this.controller.signal })
        .then((res) => res.json())
        .then((body) => body.suggestions)
        .then((suggestions) =>
          this.setState({
            state: IDLE,
            suggestions,
          })
        )
        .catch((err) => {
          if (err.code === err.ABORT_ERR) {
            return;
          }

          console.error("error making suggestions", err);
          this.setState({ suggestions: [], state: ERROR });
        });
    });
  }

  render() {
    const formClasses = ["add-item-form"];
    const inputContainerClasses = ["input-container"];
    if (this.state.state === LOADING) {
      formClasses.push("loading");
      inputContainerClasses.push("loading");
    }

    return html`<form
      class=${formClasses.join(" ")}
      onSubmit=${(ev) => this.handleFormSubmit(ev)}
    >
      <div class=${inputContainerClasses.join(" ")}>
        <input
          autocapitalize="off"
          autocomplete="off"
          autocorrect="off"
          autofocus="yes"
          name="value"
          onInput=${(ev) => this.handleInput(ev)}
          placeholder="URL"
          spellcheck="false"
          type="text"
          value=${this.state.value}
        />
        <${SpinningRing} size="30" />
      </div>
      <div class="suggestions">
        ${this.state.suggestions.map(
          (suggestion) => html`<${Suggestion} ...${suggestion} />`
        )}
      </div>
    </form>`;
  }
}

const Suggestion = ({ kind, title, url, firstChild }) =>
  html`<div class="suggestion" style=${{}}>
    <div class="suggestion-title">${title}</div>
    <div class="suggestion-url">${url}</div>
    <div class="suggestion-kind">
      <div class="suggestion-kind-container">${kind}</div>
    </div>
  </div>`;
