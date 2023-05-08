import { Component, html, render } from "/public/preact.js";
import { SpinningRing } from "/public/component.js";
import { debounce } from "/public/common.js";

const IDLE = 0;
const LOADING = 1;
const ERROR = 2;

class AddItem extends Component {
  constructor() {
    super();

    this.state = {
      state: IDLE,
      suggestions: null,
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

          console.error("error making suggestings", err);
          this.setState({ state: ERROR });
        });
    });
  }

  render() {
    const inputContainerClasses = ["input-container"];
    if (this.state.state === LOADING) {
      inputContainerClasses.push("loading");
    }

    const suggestions =
      this.state.state !== LOADING && this.state.suggestions
        ? JSON.stringify(this.state.suggestions, null, "    ")
        : null;

    return html`<form
      class="add-item-form"
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
      <pre>${suggestions}</pre>
    </form>`;
  }
}

const containerEl = document.querySelector("[data-component=add-item]");
render(html`<${AddItem} />`, containerEl);
