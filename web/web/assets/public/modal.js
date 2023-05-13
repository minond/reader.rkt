import { Component, html, render } from "/public/preact.js";

const SHOW_OFF = 0;
const SHOW_ON = 1;
const SHOW_HIDING = 2;

export default class Modal extends Component {
  static render(klass, props = {}) {
    const controller = {};
    const container = document.createElement("div");
    container.dataset.modalContainer = true;

    document.body.appendChild(container);
    render(
      html`
      <${Modal} controller=${controller}>
        <${klass} controller=${controller} ...${props} />
      </${Modal}>`,
      container
    );

    return { controller, container };
  }

  constructor() {
    super();

    this.state = {
      showState: SHOW_OFF,
    };
  }

  componentWillMount() {
    this.props.controller.show = () => this.show();
    this.props.controller.hide = () => this.hide();
  }

  hide() {
    this.setState({ showState: SHOW_HIDING }, () =>
      setTimeout(() => this.setState({ showState: SHOW_OFF }), 150)
    );
  }

  show() {
    if (this.state.showState !== SHOW_HIDING) {
      this.setState({ showState: SHOW_ON });
    }
  }

  render() {
    if (this.state.showState === SHOW_OFF) {
      return null;
    }

    const styles = {};
    if (this.state.showState === SHOW_HIDING) {
      styles.opacity = 0;
    }

    return html`<div
      class="backdrop"
      style=${styles}
      onClick=${() => this.hide()}
    >
      ${this.props.children}
    </div>`;
  }
}
