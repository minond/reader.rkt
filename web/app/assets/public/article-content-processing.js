import {
  Component,
  html,
  render,
} from "https://unpkg.com/htm/preact/standalone.module.js";

const Tag = ({ label = "", color = false, className = "fadein" }) =>
  html`<div
    class="tag ${className}"
    style="${color ? `background-color: ${color}` : ""}"
  >
    ${label}
  </div>`;

class ArticleContentProcessing extends Component {
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
      .then((summary) => this.setState({ loadingSummary: false, summary }));
  }

  fetchTags() {
    this.setState({ loadingTags: true });
    fetch(`/articles/${this.props.articleId}/tags`)
      .then((res) => res.json())
      .then((body) => body.tags)
      .then((tags) => this.sortTags(tags))
      .then((tags) => this.setState({ loadingTags: false, tags }));
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
      return html`<div class="summary"></div>`;
    } else {
      return html`<div
        class="summary"
        dangerouslySetInnerHTML=${{ __html: this.state.summary }}
      ></div>`;
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

const containerEl = document.querySelector(
  "[data-component=article-content-processing]"
);
const articleId = containerEl.getAttribute("data-article-id");

render(
  html`<${ArticleContentProcessing} articleId=${articleId} />`,
  containerEl
);
