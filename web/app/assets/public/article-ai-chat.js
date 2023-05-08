import markdownIt from "https://cdn.jsdelivr.net/npm/markdown-it@13.0.1/+esm";
import { Component, html, render } from "/public/preact.js";
import { SpinningRing } from "/public/component.js";
import { debounce } from "/public/common.js";

const renderer = markdownIt({ breaks: true });

const Message = ({ role, time, content }) =>
  html`<div class="message ${role}">
    <span
      dangerouslySetInnerHTML=${{ __html: renderer.render(content) }}
    ></span>
    <time>${new Date(time).toLocaleString()}</time>
  </div>`;

class ArticleAIChat extends Component {
  constructor() {
    super();

    this.rootElementRef = { current: null };
    this.messagesElementRef = { current: null };

    this.toggleMessagesShadowDebounced = debounce(
      this.toggleMessagesShadow.bind(this),
      10
    );
    this.recalculateMessagesSizeDebounced = debounce(
      this.recalculateMessagesSize.bind(this),
      10
    );

    this.state = {
      messagesMaxHeight: null,
      messagesAnimated: false,
      shadowOpacity: 1,
      loading: false,
      chatInputValue: null,
      chat: [],
      chatMessage: null,
    };
  }

  componentWillMount() {
    window.addEventListener("scroll", this.recalculateMessagesSizeDebounced);
    window.addEventListener("resize", this.recalculateMessagesSizeDebounced);
  }

  componentDidMount() {
    this.setState({ chat: this.readChatFromStore() }, () => {
      this.toggleMessagesShadow();
      this.recalculateMessagesSize();
      this.scrollToLastMessage();

      setTimeout(() => {
        this.recalculateMessagesSize();
        this.scrollToLastMessage();
        this.setState({ messagesAnimated: true });
      }, 100);
    });
  }

  componentWillUnmount() {
    window.removeEventListener("scroll", this.recalculateMessagesSizeDebounced);
    window.removeEventListener("resize", this.recalculateMessagesSizeDebounced);
  }

  readChatFromStore() {
    const key = `reader/chat/${this.props.articleId}`;
    const storedChat = localStorage.getItem(key);
    return storedChat ? JSON.parse(storedChat) : [];
  }

  writeChatToStore() {
    const key = `reader/chat/${this.props.articleId}`;
    localStorage.setItem(key, JSON.stringify(this.state.chat));
  }

  stickyChat() {
    return !!this.state.chat.length;
  }

  handleChatInputKeyPress(ev) {
    switch (ev.keyCode) {
      case 13:
        const message = ev.target.value;
        if (message) {
          this.sendMessage(message);
        }

        ev.preventDefault();
        return false;
    }
  }

  sendMessage(content) {
    this.setStateWithMessage(
      "user",
      content,
      {
        loading: true,
        chatInputValue: "",
      },
      () => {
        fetch(`/articles/${this.props.articleId}/chat`, {
          method: "POST",
          body: JSON.stringify({
            chat: this.state.chat.map((message) => ({
              role: message.role,
              content: message.content,
            })),
          }),
        })
          .then((res) => res.json())
          .then((body) => body.response)
          .then((response) =>
            this.setStateWithMessage("assistant", response, {
              loading: false,
            })
          )
          .catch((err) => {
            this.setState({ loading: false });
            console.error("error sending chat message", err);
          });
      }
    );
  }

  setStateWithMessage(role, content, extraState, cb) {
    this.setState(
      {
        ...extraState,
        chat: [...this.state.chat, this.makeMessage(role, content)],
      },
      () => {
        this.writeChatToStore();
        this.recalculateMessagesSizeDebounced();
        this.scrollToLastMessage();
        if (cb) {
          cb();
        }
      }
    );
  }

  makeMessage(role, content) {
    const time = new Date().valueOf();
    return { role, content, time };
  }

  scrollToLastMessage() {
    if (!this.messagesElementRef.current) {
      return;
    }

    const el = this.messagesElementRef.current.querySelector(
      ".message:last-child"
    );
    if (el) {
      this.messagesElementRef.current.scrollTo(0, el.offsetTop);
    }
  }

  toggleMessagesShadow() {
    if (!this.messagesElementRef.current) {
      return;
    }

    this.setState({
      shadowOpacity: this.messagesElementRef.current.scrollTop < 10 ? 0 : 1,
    });
  }

  recalculateMessagesSize() {
    if (!this.rootElementRef.current) {
      return;
    }

    const verticalMargins = 100;
    const messagesMaxHeight = Math.max(
      innerHeight -
        this.rootElementRef.current.getBoundingClientRect().top -
        verticalMargins,
      150
    );

    this.setState({ messagesMaxHeight });
  }

  render() {
    const chatClasses = ["chat"];
    if (this.stickyChat()) {
      chatClasses.push("sticky");
    }
    if (this.state.loading) {
      chatClasses.push("loading");
    }

    let shadowStyles = `opacity: ${this.state.shadowOpacity}`;
    let messagesStyles = "";
    if (this.state.messagesMaxHeight) {
      messagesStyles = `max-height: ${this.state.messagesMaxHeight}px`;
    }

    const messagesClasses = ["messages"];
    if (this.state.messagesAnimated) {
      messagesClasses.push("animate");
    }

    return html`<div
      class="${chatClasses.join(" ")}"
      ref=${this.rootElementRef}
    >
      <div
        class="${messagesClasses.join(" ")}"
        style=${messagesStyles}
        ref=${this.messagesElementRef}
        onScroll=${this.toggleMessagesShadowDebounced}
      >
        ${this.state.chat.map(
          (message) =>
            html`<${Message}
              role=${message.role}
              time=${message.time}
              content=${message.content}
            />`
        )}
      </div>
      <div class="shadow" style=${shadowStyles}></div>
      <div class="input-wrapper">
        <textarea
          onKeyPress=${(ev) => this.handleChatInputKeyPress(ev)}
          disabled=${this.state.loading}
          value=${this.state.chatInputValue}
          rows="1"
          placeholder="Send a message..."
        ></textarea>
        <${SpinningRing} size="30" />
      </div>
      <p class="disclaimer">
        ChatGPT may produce inaccurate information about people, places, or
        facts.
      </p>
    </div>`;
  }
}

const containerEl = document.querySelector("[data-component=article-ai-chat]");
const articleId = containerEl.getAttribute("data-article-id");
render(
  html`<${ArticleAIChat} articleId=${articleId} />`,
  containerEl.parentNode,
  containerEl
);
