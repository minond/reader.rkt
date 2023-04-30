import {
  Component,
  html,
  render,
} from "https://unpkg.com/htm/preact/standalone.module.js";
import Subscriber from "/public/subscriber.js";

const userId = document.body.getAttribute("data-user-id");
const port = 8082;
const protocol = window.location.protocol === "http:" ? "ws:" : "wss:";
const hostname = window.location.hostname;
const sub = new Subscriber(`${protocol}//${hostname}:${port}`);
const articleCreatedChannel = `user/${userId}/article/created`;
const containerEl = document.querySelector(".reload-page-container");

sub.subscribe(articleCreatedChannel, (payload) => {
  sub.unsubscribe(articleCreatedChannel);
  setTimeout(() => render(html`<${ReloadPage} />`, containerEl), 500);
});

class ReloadPage extends Component {
  reloadPage() {
    fetch(location.pathname, { headers: { Accept: "application/json" } })
      .then((res) => res.json())
      .then((res) => {
        document.querySelector("main").classList.add("fadein");
        document.querySelector("main").innerHTML = res.html;
      });
  }

  render() {
    return html`
      <p class="fadein">
        <span>New articles just came in and are ready for you, click </span>
        <span class="link" onClick=${() => this.reloadPage()}>here</span>
        <span> to see them now.</span>
      </p>
    `;
  }
}
