import {
  Component,
  html,
  render,
} from "https://unpkg.com/htm/preact/standalone.module.js";

const Tag = ({ label, color, id }) =>
  html`<div class="tag" style="background-color: ${color}">${label}</div>`;

class ArticleContentProcessing extends Component {
  constructor() {
    super();
    this.state = { tags: [] };
  }

  fetchTags() {
    fetch(`/articles/${this.props.articleId}/tags`)
      .then((res) => res.json())
      .then((body) => body.tags)
      .then((tags) => this.sortTags(tags))
      .then((tags) => this.setState({ tags }));
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
  }

  render() {
    return html`<div class="tags fadein">${this.state.tags.map(Tag)}</div>`;
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
