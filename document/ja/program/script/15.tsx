//

import axios from "axios";
import * as queryParser from "query-string";
import * as react from "react";
import {
  Component,
  Fragment,
  ReactNode
} from "react";
import {
  render
} from "react-dom";
import {
  ExecutorBase
} from "./module/executor";
import {
  RootBase
} from "./module/search";


export class Match {

  public name!: string;
  public path!: string;
  public splits!: Array<[string, string, string]>;

  public constructor(object: object) {
    Object.assign(this, object);
  }

}


type RawResult = {matches: Array<object>, hitSize: number};
type Result = {matches: Array<Match>, hitSize: number};

type RootState = {
  search: string,
  mode: number,
  page: number,
  result: Result,
  errorMessage: string | null
};


export class Root extends RootBase<{}, RootState> {

  public state: RootState = {
    search: "",
    mode: 0,
    page: 0,
    result: {matches: [], hitSize: 0},
    errorMessage: null
  };

  protected async updateResultsBase(): Promise<void> {
    let response = await axios.get("../../program/interface/4.cgi?mode=search&" + this.deserializeQueryBase(), {validateStatus: () => true});
    if (response.status === 200 && !("error" in response.data)) {
      let rawResult = response.data as RawResult;
      let matches = rawResult.matches.map((match) => new Match(match));
      let hitSize = rawResult.hitSize;
      let errorMessage = null;
      let result = {matches, hitSize};
      this.setState({result, errorMessage});
    } else {
      let errorMessage = response.data.message;
      let result = {matches: [], hitSize: 0};
      this.setState({result, errorMessage});
    }
  }

  protected serializeQueryBase(): RootState {
    let query = queryParser.parse(window.location.search);
    let nextState = {} as any;
    nextState.search = (typeof query["search"] === "string") ? query["search"] : "";
    nextState.mode = (typeof query["type"] === "string") ? +query["type"] : 0;
    nextState.page = (typeof query["page"] === "string") ? +query["page"] : 0;
    return nextState;
  }

  protected deserializeQueryBase(overriddenState?: Partial<RootState>): string {
    let query = {} as any;
    let state = Object.assign({}, this.state, overriddenState);
    query["search"] = state.search;
    query["type"] = state.mode;
    query["page"] = state.page;
    let queryString = queryParser.stringify(query);
    return queryString;
  }

  private renderForm(): ReactNode {
    let node = (
      <Fragment>
        <h1>検索フォーム</h1>
        <form onSubmit={(event) => event.preventDefault()}>
          <input type="text" name="search" value={this.state.search} onChange={(event) => this.handleSearchChange({search: event.target.value})}/>
          <br/>
          <input type="radio" name="type" value="0" id="type-0" checked={this.state.mode === 0} onChange={() => this.handleSearchChange({mode: 0})}/>
          <label htmlFor="type-0">全文</label>{"　"}
          <input type="radio" name="type" value="1" id="type-1" checked={this.state.mode === 1} onChange={() => this.handleSearchChange({mode: 1})}/>
          <label htmlFor="type-1">シャレイア語</label>
        </form>
      </Fragment>
    );
    return node;
  }

  private renderResult(): ReactNode {
    let result = this.state.result;
    let matchNodes = result.matches.map((match, index) => {
      return <MatchPane match={match} key={index}/>;
    });
    let node = (
      <Fragment>
        <h1>検索結果</h1>
        {matchNodes}
      </Fragment>
    );
    return node;
  }

  public render(): ReactNode {
    let resultNode = (() => {
      if (this.state.errorMessage === null) {
        return <Fragment>{this.renderResult()}{this.renderNumber(15)}</Fragment>;
      } else {
        return this.renderErrorMessage();
      }
    })();
    let node = (
      <Fragment>
        {this.renderForm()}
        {resultNode}
      </Fragment>
    );
    return node;
  }

}


export class MatchPane extends Component<{match: Match}> {

  private renderHead(): ReactNode {
    let match = this.props.match;
    let node = (
      <div className="head">
        <span className="head-name">
          <a href={match.path}>{match.name}</a>
        </span>
      </div>
    );
    return node;
  }

  private renderSplits(): ReactNode {
    let match = this.props.match;
    let innerNodes = match.splits.map((split, index) => {
      let innerNode = (
        <li key={index}>
          {split[0]}
          <span className="match">{split[1]}</span>
          {split[2]}
        </li>
      );
      return innerNode;
    });
    let node = (
      <ul>
        {innerNodes}
      </ul>
    );
    return node;
  }

  private renderBody(): ReactNode {
    let match = this.props.match;
    let node = (
      <div className="result-wrapper">
        <div className="border"/>
        <div className="result">
          {match.splits.length > 0 && this.renderSplits()}
        </div>
      </div>
    );
    return node;
  }

  public render(): ReactNode {
    let node = (
      <Fragment>
        {this.renderHead()}
        {this.renderBody()}
      </Fragment>
    );
    return node;
  }

}


ExecutorBase.addLoadListener(() => {
  render(<Root/>, document.getElementById("root"));
});