import {
  Component,
  html,
  render,
} from "https://unpkg.com/htm@3.1.1/preact/standalone.module.js";
import { SpinningRing } from "/public/shared-components.js";

class AddItem extends Component {
  constructor() {
    super();

    this.state = {
      suggestions: null,
      loading: false,
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
    this.setState({ loading: true }, () => {
      fetch(url, { signal: this.controller.signal })
        .then((res) => res.json())
        .then((suggestions) =>
          this.setState({
            suggestions,
            loading: false,
          })
        )
        .catch((err) => {
          if (err.code === err.ABORT_ERR) {
            return;
          }

          console.error("error making suggestings", err);
        });
    });
  }

  render() {
    const inputContainerClasses = ["input-container"];
    if (this.state.loading) {
      inputContainerClasses.push("loading");
    }

    const suggestions =
      !this.state.loading && this.state.suggestions
        ? JSON.stringify(this.state.suggestions)
        : null;

    return html`<form onSubmit=${(ev) => this.handleFormSubmit(ev)}>
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
      ${suggestions}
    </form>`;
  }
}

function debounce(fn, time) {
  let timer;

  return function (...args) {
    clearTimeout(timer);
    timer = setTimeout(fn.bind(null, ...args), time);
  };
}

const containerEl = document.querySelector("[data-component=add-item]");
render(html`<${AddItem} />`, containerEl);
