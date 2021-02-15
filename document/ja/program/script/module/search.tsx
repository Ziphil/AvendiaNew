//

import * as react from "react";
import {
  Component,
  Fragment,
  ReactNode,
  SyntheticEvent
} from "react";
import {
  debounce
} from "./debounce";


type ResultBase = {
  hitSize: number
};
type RootBaseState = {
  page: number,
  result: ResultBase
  errorMessage: string | null
};


export abstract class RootBase<P, S extends RootBaseState> extends Component<P, S> {

  public async componentDidMount(): Promise<void> {
    this.deserializeQuery(false, () => {
      this.updateResultsImmediately(false);
    });
  }

  protected abstract updateResultsBase(): Promise<void>;

  protected async updateResultsImmediately(serialize: boolean = true): Promise<void> {
    await this.updateResultsBase();
    if (serialize) {
      this.serializeQuery();
    }
  }

  @debounce(500)
  protected async updateResults(serialize: boolean = true): Promise<void> {
    await this.updateResultsBase();
    if (serialize) {
      this.serializeQuery();
    }
  }

  protected abstract deserializeQueryBase(): S;

  protected abstract serializeQueryBase(overriddenState?: Partial<S>): string;

  protected deserializeQuery(first: boolean, callback?: () => void): void {
    let nextState = this.deserializeQueryBase();
    if (first) {
      this.state = Object.assign(this.state, nextState);
      if (callback) {
        callback();
      }
    } else {
      this.setState(nextState, callback);
    }
  }

  protected serializeQuery(callback?: () => void): void {
    let queryString = this.serializeQueryBase();
    let url = window.location.origin + window.location.pathname;
    window.history.replaceState({}, document.title, url + "?" + queryString);
    if (callback) {
      callback();
    }
  }

  protected handleSearchChange(nextState: Partial<S>, event?: SyntheticEvent): void {
    let page = 0;
    let anyNextState = nextState as any;
    this.setState({...anyNextState, page}, () => {
      this.updateResults();
    });
    event?.preventDefault();
  }

  protected handlePageChange(nextState: Partial<S>, event?: SyntheticEvent): void {
    let anyNextState = nextState as any;
    this.setState({...anyNextState}, async () => {
      window.scrollTo(0, 0);
      await this.updateResultsImmediately(true);
    });
    event?.preventDefault();
  }

  protected renderErrorMessage(): ReactNode {
    let errorMessage = this.state.errorMessage!;
    let lineNodes = errorMessage.split(/\r\n|\r|\n/).map((line, index) => {
      return <tr key={index}><td>{line}</td></tr>;
    });
    let node = (
      <Fragment>
        <h1>エラー</h1>
        <div className="code-wrapper">
          <div className="code-inner-wrapper">
            <table className="code">
              <tbody>
                {lineNodes}
              </tbody>
            </table>
          </div>
        </div>
      </Fragment>
    );
    return node;
  }

  protected renderNumber(size: number): ReactNode {
    let page = this.state.page;
    let hitSize = this.state.result.hitSize;
    let url = window.location.origin + window.location.pathname;
    let leftArrowNode = (() => {
      if (page > 0) {
        let nextState = {page: page - 1} as any;
        let queryString = this.serializeQueryBase(nextState);
        return <a className="left-arrow" href={url + "?" + queryString} onClick={(event) => this.handlePageChange(nextState, event)}/>;
      } else {
        return <span className="left-arrow invalid"/>;
      }
    })();
    let rightArrowNode = (() => {
      if (page * size + size < hitSize) {
        let nextState = {page: page + 1} as any;
        let queryString = this.serializeQueryBase(nextState);
        return <a className="right-arrow" href={url + "?" + queryString} onClick={(event) => this.handlePageChange(nextState, event)}/>;
      } else {
        return <span className="right-arrow invalid"/>;
      }
    })();
    let fractionNode = (
      <div className="fraction">
        <div className="page">{Math.min(page * size + 1, hitSize)} ～ {Math.min(page * size + size, hitSize)}</div>
        <div className="total">{hitSize}</div>
      </div>
    );
    let node = (
      <div className="number">
        {leftArrowNode}
        {fractionNode}
        {rightArrowNode}
      </div>
    );
    return node;
  }

}