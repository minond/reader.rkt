window.addEventListener("click", (ev) => {
  const fancyLink = childOf(ev.target, (node) => node?.dataset?.fancyLink);
  if (fancyLink) {
    fetch(fancyLink.href)
      .then(() =>
        fetch(location.pathname, { headers: { Accept: "application/json" } })
          .then((res) => res.json())
          .then((res) => (document.querySelector("main").innerHTML = res.html))
      )
      .catch((err) => console.error("error with fancy link:", error));
    ev.preventDefault();
    return false;
  }
});

function childOf(el, fn) {
  while (el) {
    if (fn(el)) {
      return el;
    }
    el = el.parentNode;
  }
  return false;
}
