export default class Subscriber {
  #ready = false;
  #subscriptions = [];
  #socket = null;

  /**
   * @param {String} url
   */
  constructor(url) {
    this.#socket = new WebSocket(url);
    this.#waitForConnection();
    this.#setupListener();
  }

  /**
   * @param {String} channel
   * @param {Function} callback
   */
  subscribe(channel, callback) {
    const subscription = new Subscription(channel, callback);
    this.#subscriptions.push(subscription);
    this.#startSubscriptions();
  }

  /**
   * @param {String} channel
   * @param {Function} callback
   */
  unsubscribe(channel, callback) {
    this.#subscriptions = this.#subscriptions.filter((subscription) =>
      callback
        ? subscription.channel !== channel || subscription.callback !== callback
        : subscription.channel !== channel
    );

    const needsSubscription =
      this.#subscriptions.filter(
        (subscription) => subscription.channel === channel
      ).length !== 0;
    if (!needsSubscription) {
      this.#socket.send(`unsubscribe ${channel}`);
    }
  }

  #waitForConnection() {
    this.#socket.addEventListener("open", (event) => {
      this.#ready = true;
      this.#startPingPong();
      this.#startSubscriptions();
    });
  }

  #startPingPong() {
    setInterval(() => this.#socket.send("ping"), 60000);
  }

  #startSubscriptions() {
    if (!this.#ready) {
      return;
    }

    const channels = new Set(
      this.#subscriptions.map((subscription) => subscription.channel)
    );
    channels.forEach((channel) => this.#socket.send(`subscribe ${channel}`));
  }

  #setupListener() {
    this.#socket.addEventListener("message", (event) => {
      if (event.data === "pong") {
        return;
      }

      const msg = JSON.parse(event.data);
      const payload = JSON.parse(msg.payload);
      this.#subscriptions.forEach((subscription) => {
        if (subscription.channel === msg.channel) {
          subscription.callback(payload);
        }
      });
    });
  }
}

class Subscription {
  constructor(channel, callback) {
    this.channel = channel;
    this.callback = callback;
  }
}
