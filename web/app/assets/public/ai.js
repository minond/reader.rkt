import markdownIt from "https://cdn.jsdelivr.net/npm/markdown-it@13.0.1/+esm";

const chatEl = document.querySelector(".chat");
const inputEl = document.querySelector(".chat textarea");
const shadowEl = document.querySelector(".chat .shadow");
const messagesEl = document.querySelector(".chat .messages");
const summaryEl = document.querySelector("#summary");
const loadingSummaryEl = document.querySelector("#summary .loading-summary");
const articleIdEl = document.querySelector("#article-id");
const articleId = articleIdEl.value;

const renderer = markdownIt({ breaks: true });
const storageKey = `reader/chat/${articleId}`;
const storedChat = localStorage.getItem(storageKey);
const chat = storedChat ? JSON.parse(storedChat) : [];

loadSummary((wasLoaded) => {
  showChat(!wasLoaded);
  loadChat();
  initChat();
  setMessagesContainerSize();
  scrollToBottomOfMessages();
});

function loadSummary(onLoaded) {
  if (loadingSummaryEl && articleIdEl) {
    fetch(`/articles/${articleId}/summary`)
      .then((res) => res.json())
      .then((body) => {
        const p = document.createElement("p");
        p.classList.add("fadein");
        p.innerHTML = body.summary;
        return p;
      })
      .catch((err) => {
        const p = document.createElement("p");
        p.classList.add("fadein");
        p.innerText =
          "There was an error generating a summary for this document at this time. Please try again later.";
        return p;
      })
      .then((p) => {
        summaryEl.removeChild(loadingSummaryEl);
        summaryEl.appendChild(p);
      })
      .finally(() => {
        try {
          onLoaded(false);
        } catch (err) {}
      });
  } else {
    onLoaded(true);
  }
}

function showChat(fadeIn) {
  if (fadeIn) {
    chatEl.classList.add("fadein");
  }
  chatEl.classList.remove("dn");
}

function loadChat() {
  chat.forEach((message) => showMessage(message, false));
}

function initChat() {
  const toggleMessagesShadowDebounced = debounce(toggleMessagesShadow, 10);
  const setMessagesContainerSizeDebounced = debounce(
    setMessagesContainerSize,
    10
  );

  inputEl.addEventListener("keypress", handleChatInput);
  messagesEl.addEventListener("scroll", toggleMessagesShadowDebounced);
  window.addEventListener("scroll", setMessagesContainerSizeDebounced);
  window.addEventListener("resize", setMessagesContainerSizeDebounced);
}

function handleChatInput(ev) {
  switch (ev.keyCode) {
    case 13:
      sendMessage();
      ev.preventDefault();
      return false;
  }
}

function toggleMessagesShadow() {
  shadowEl.style.opacity = messagesEl.scrollTop < 10 ? 0 : 1;
}

function scrollToBottomOfMessages() {
  messagesEl.scrollTo(0, messagesEl.scrollHeight);
}

function setMessagesContainerSize() {
  const verticalMargins = 100;
  const maxHeight = Math.max(
    innerHeight - chatEl.getBoundingClientRect().top - verticalMargins,
    150
  );
  messagesEl.style.maxHeight = `${maxHeight}px`;
}

function sendMessage() {
  let content = inputEl.value;
  if (!content) {
    return;
  }

  storeMessage("user", content);
  inputEl.value = "";
  inputEl.disabled = true;
  chatEl.classList.add("loading");

  fetch(`/articles/${articleId}/chat`, {
    method: "POST",
    body: JSON.stringify({
      chat: chat.map((message) => ({
        role: message.role,
        content: message.content,
      })),
    }),
  })
    .then((res) => res.json())
    .then((body) => {
      inputEl.disabled = false;
      chatEl.classList.remove("loading");
      storeMessage("assistant", body.response);
    });
}

function storeMessage(role, content) {
  const time = new Date().valueOf();
  const message = { role, content, time };
  chat.push(message);
  showMessage(message);
  localStorage.setItem(storageKey, JSON.stringify(chat));
}

function showMessage(message, animate = true) {
  const container = document.createElement("div");
  container.innerHTML = renderer.render(message.content);
  container.classList.add("message");
  container.classList.add(message.role);
  if (animate) container.classList.add("fadein");

  const timestamp = document.createElement("time");
  timestamp.innerText = new Date(message.time).toLocaleString();

  container.appendChild(timestamp);
  messagesEl.appendChild(container);
  scrollToBottomOfMessages();
  makeChatSticky();
}

function makeChatSticky() {
  chatEl.style.top = "30px";
}

function debounce(fn, time) {
  let timer;

  return function (...args) {
    clearTimeout(timer);
    timer = setTimeout(fn.bind(null, ...args), time);
  };
}