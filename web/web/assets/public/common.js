export function debounce(fn, time) {
  let timer;

  return function (...args) {
    clearTimeout(timer);
    timer = setTimeout(fn.bind(null, ...args), time);
  };
}
