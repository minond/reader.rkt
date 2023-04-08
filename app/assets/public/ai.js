import markdownIt from "https://cdn.jsdelivr.net/npm/markdown-it@13.0.1/+esm";

const chatEl = document.querySelector(".chat");
const messageEl = document.querySelector(".chat textarea");
const messagesEl = document.querySelector(".chat .messages");
const summaryEl = document.querySelector("#summary");
const loadingSummaryEl = document.querySelector("#summary .loading-summary");
const articleIdEl = document.querySelector("#article-id");
const articleId = articleIdEl.value;

const renderer = markdownIt({ breaks: true });
const storageKey = `reader/chat/${articleId}`;
const storedChat = localStorage.getItem(storageKey);
const chat = storedChat ? JSON.parse(storedChat) : [];

loadSummary();
loadChat();
initChat();

function loadSummary() {
  if (loadingSummaryEl && articleIdEl) {
    fetch(`/articles/${articleId}/summary`)
      .then((res) => res.json())
      .then((body) => {
        const p = document.createElement("p");
        p.classList.add("fadein");
        p.innerHTML = body.summary;
        summaryEl.removeChild(loadingSummaryEl);
        summaryEl.appendChild(p);
      });
  }
}

function loadChat() {
  chat.forEach((message) => showMessage(message, false));
}

function initChat() {
  messageEl.addEventListener("keypress", function (ev) {
    switch (ev.keyCode) {
      case 13:
        sendMessage();
        ev.preventDefault();
        return false;
    }
  });
}

function sendMessage() {
  let content = messageEl.value;
  if (!content) {
    return;
  }

  storeMessage("user", content);
  messageEl.value = "";
  messageEl.disabled = true;
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
      messageEl.disabled = false;
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
}
