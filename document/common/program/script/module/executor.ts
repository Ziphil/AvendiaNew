//


export abstract class ExecutorBase {

  protected abstract prepare(): void;

  public static regsiter<E extends ExecutorBase>(this: new() => E): void {
    let executor = new this();
    window.addEventListener("load", () => {
      executor.prepare();
    });
  }

  public static addLoadListener(listener: (event: Event) => any): void {
    window.addEventListener("load", listener);
  }

}