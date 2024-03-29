import markdownIt from "https://cdn.jsdelivr.net/npm/markdown-it@13.0.1/+esm";
import { Component, html, render } from "/public/preact.js";

const renderer = markdownIt({ breaks: true });

export default class ArticleProcessing extends Component {
  constructor() {
    super();
    this.state = {
      loadingSummary: false,
      loadingTags: false,
      summary: null,
      tags: [],
    };
  }

  fetchSummary() {
    this.setState({ loadingSummary: true });
    fetch(`/articles/${this.props.articleId}/summary`)
      .then((res) => res.json())
      .then((body) => body.summary)
      .then((summary) => this.setState({ loadingSummary: false, summary }))
      .catch((err) => {
        this.setState({ loadingSummary: false, summary: "" });
        console.error("error loading article summary", err);
      });
  }

  fetchTags() {
    this.setState({ loadingTags: true });
    fetch(`/articles/${this.props.articleId}/tags`)
      .then((res) => res.json())
      .then((body) => body.tags)
      .then((tags) => this.sortTags(tags))
      .then((tags) => this.setState({ loadingTags: false, tags }))
      .catch((err) => {
        this.setState({ loadingTags: false, tags: [] });
        console.error("error loading article tags", err);
      });
  }

  sortTags(tags) {
    return tags.sort((a, b) => {
      if (a.label < b.label) {
        return -1;
      } else if (a.label > b.label) {
        return 1;
      } else {
        return 0;
      }
    });
  }

  componentWillMount() {
    this.fetchTags();
    this.fetchSummary();
  }

  renderSummary() {
    if (this.state.loadingSummary) {
      return html`<div class="summary loading">
        <div class="line pulse"></div>
        <div class="line pulse"></div>
        <div class="line pulse"></div>
      </div>`;
    } else if (this.state.summary) {
      return html`<div
        class="summary fadein"
        dangerouslySetInnerHTML=${{
          __html: renderer.render(`**Summary:** ${this.state.summary}`),
        }}
      ></div>`;
    } else {
      return null;
    }
  }

  renderTags() {
    if (this.state.loadingTags) {
      return html`<div class="tags">
        ${Array.from(Array(15).keys())
          .map(() => Math.floor(Math.random() * (10 - 4 + 1)) + 4)
          .map(
            (w) => html`<${Tag} className="loading pulse w--${w}" label=" " />`
          )}
      </div>`;
    } else {
      return html`<div class="tags">${this.state.tags.map(Tag)}</div>`;
    }
  }

  render() {
    return [this.renderSummary(), this.renderTags()];
  }
}

const Tag = ({ label = "", color = false, className = "fadein" }) =>
  html`<div
    class="tag ${className}"
    style="${color ? `background-color: ${color}` : ""}"
  >
    ${label}
  </div>`;
