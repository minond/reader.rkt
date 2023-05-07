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
      deduction: null,
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

    this.setState({ loading: true }, () => {
      fetch(this.itemDeduceURL(), { signal: this.controller.signal })
        .then((res) => res.json())
        .then((deduction) =>
          this.setState({
            deduction,
            loading: false,
          })
        )
        .catch((err) => {
          if (err.code === err.ABORT_ERR) {
            return;
          }

          console.error("error deducing item", err);
        });
    });
  }

  itemDeduceURL() {
    return `/item/deduce?url=${encodeURIComponent(this.state.value.trim())}`;
  }

  render() {
    const inputContainerClasses = ["input-container"];
    if (this.state.loading) {
      inputContainerClasses.push("loading");
    }

    const deductions =
      !this.state.loading && this.state.deduction
        ? JSON.stringify(this.state.deduction)
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
      ${deductions}
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
