import { html } from "/public/preact.js";

export const SpinningRing = ({ size }) => {
  const sizeHalf = Math.floor(size / 2);
  const containerStyles = `height: ${size}px; width: ${size}px`;
  const pieceStyles = `height: ${sizeHalf}px; width: ${sizeHalf}px`;
  return html`<div class="spinning-ring" style=${containerStyles}>
    <div style=${pieceStyles}></div>
    <div style=${pieceStyles}></div>
    <div style=${pieceStyles}></div>
    <div style=${pieceStyles}></div>
  </div>`;
};
