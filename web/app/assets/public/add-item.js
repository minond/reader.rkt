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
    const inputContainerClasses = ["input-container"];
    if (this.state.state === LOADING) {
      inputContainerClasses.push("loading");
    }

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
      <div
        class="suggestions"
        style=${{
          border: "1px solid rgb(207, 207, 207)",
          padding: ".5em",
          borderRadius: "3px",
        }}
      >
        ${this.state.suggestions.map(
          (suggestion) => html`<${Suggestion} ...${suggestion} />`
        )}
      </div>
    </form>`;
  }
}

const Suggestion = ({ kind, title, url }) =>
  html`<div
    class="suggestion"
    style=${{
      display: "grid",
      gridGap: "0px",
      gridTemplateColumns: "90% 10%",
    }}
  >
    <div
      class="suggestion-title"
      style=${{
        gridColumn: "1",
        fontWeight: "bold",
      }}
    >
      ${title}
    </div>
    <div
      class="suggestion-url"
      style=${{
        gridColumn: "1",
        color: "gray",
      }}
    >
      ${url}
    </div>
    <div
      class="suggestion-kind"
      style=${{
        gridColumn: "2",
        gridRow: "1 / span 2",
        alignSelf: "center",
      }}
    >
      <div
        class="suggestion-kind-container"
        style=${{
          border: "1px solid rgb(245, 223, 70)",
          display: "inline-block",
          padding: "1px 6px",
          margin: "0",
          fontSize: ".8em",
          backgroundColor: "rgba(255, 249, 208, 1)",
          fontWeight: "bold",
          textTransform: "lowercase",
        }}
      >
        ${kind}
      </div>
    </div>
  </div>`;
