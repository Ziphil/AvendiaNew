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


type Equivalent = {category: string, names: Array<string>};
type Content = {type: string, text: string};
type Example = {type: "例文", shaleian: string, japanese: string};
type Synonym = {category: string, names: Array<string>};


export class Word {

  public name!: string;
  public pronunciation!: string | null;
  public date!: number;
  public sort!: string;
  public equivalents!: Array<Equivalent>;
  public contents!: Array<Content>;
  public examples!: Array<Example>;
  public synonyms!: Array<Synonym>;

  public constructor(object: object) {
    Object.assign(this, object);
  }

}


export class Suggestion {

  public explanation!: string;
  public name!: string;

  public constructor(object: object) {
    Object.assign(this, object);
  }

}


type RawResult = {words: Array<object>, suggestions: Array<object>};
type Result = {words: Array<Word>, suggestions: Array<Suggestion>};

type RootState = {
  search: string,
  mode: number,
  type: number,
  version: number,
  random: boolean,
  page: number,
  result: Result
};


export class Root extends Component<{}, RootState> {

  public state: RootState = {
    search: "",
    mode: 3,
    type: 0,
    page: 0,
    version: 0,
    random: false,
    result: {words: [], suggestions: []}
  };

  public constructor(props: {}) {
    super(props);
    this.serializeQuery(true);
  }

  public async componentDidMount(): Promise<void> {
    await this.updateResultsImmediately(false);
  }

  private async updateResultsImmediately(deserialize: boolean = true): Promise<void> {
    let response = await axios.get("../../program/interface/3.cgi?mode=search&" + this.deserializeQueryBase());
    if (response.status === 200 && !("error" in response.data)) {
      let rawResult = response.data as RawResult;
      let words = rawResult.words.map((word) => new Word(word));
      let suggestions = rawResult.suggestions.map((suggestion) => new Suggestion(suggestion));
      let result = {words, suggestions};
      this.setState({result});
    } else {
      let result = {words: [], suggestions: []};
      this.setState({result});
    }
    if (deserialize) {
      this.deserializeQuery();
    }
  }

  private async updateResults(): Promise<void> {
    await this.updateResultsImmediately();
  }

  private serializeQuery(first: boolean, callback?: () => void): void {
    let nextState = this.serializeQueryBase();
    if (first) {
      this.state = Object.assign(this.state, nextState);
      if (callback) {
        callback();
      }
    } else {
      this.setState(nextState, callback);
    }
  }

  private deserializeQuery(): void {
    let queryString = this.deserializeQueryBase();
    window.history.replaceState({}, document.title, window.location.origin + window.location.pathname + "?" + queryString);
  }

  private serializeQueryBase(): RootState {
    let query = queryParser.parse(window.location.search);
    let nextState = {} as any;
    nextState.search = (typeof query["search"] === "string") ? query["search"] : "";
    nextState.mode = (typeof query["type"] === "string") ? +query["type"] : 3;
    nextState.type = (typeof query["agree"] === "string") ? +query["agree"] : 0;
    nextState.version = (typeof query["version"] === "string") ? +query["version"] : 0;
    nextState.random = (typeof query["random"] === "string") ? query["random"] === "1" : false;
    nextState.page = (typeof query["page"] === "string") ? +query["page"] : 0;
    return nextState;
  }

  private deserializeQueryBase(): string {
    let query = {} as any;
    query["search"] = this.state.search;
    query["type"] = this.state.mode;
    query["agree"] = this.state.type;
    query["version"] = this.state.version;
    query["random"] = +this.state.random;
    query["page"] = this.state.page;
    let queryString = queryParser.stringify(query);
    return queryString;
  }

  private async handleChange(nextState: Partial<RootState>): Promise<void> {
    let page = 0;
    let anyNextState = nextState as any;
    this.setState({...anyNextState, page}, () => {
      this.updateResults();
    });
  }

  private renderForm(): ReactNode {
    let node = (
      <Fragment>
        <h1>検索フォーム</h1>
        <form>
          <input type="text" name="search" value={this.state.search} onChange={(event) => this.handleChange({search: event.target.value})}/>
          <br/>
          <input type="radio" name="type" value="3" id="type-3" checked={this.state.mode === 3} onChange={() => this.handleChange({mode: 3})}/>
          <label htmlFor="type-3">単語<span className="japanese">＋</span>訳語</label>{"　"}
          <input type="radio" name="type" value="0" id="type-0" checked={this.state.mode === 0} onChange={() => this.handleChange({mode: 0})}/>
          <label htmlFor="type-0">単語</label>{"　"}
          <input type="radio" name="type" value="1" id="type-1" checked={this.state.mode === 1} onChange={() => this.handleChange({mode: 1})}/>
          <label htmlFor="type-1">訳語</label>{"　"}
          <input type="radio" name="type" value="2" id="type-2" checked={this.state.mode === 2} onChange={() => this.handleChange({mode: 2})}/>
          <label htmlFor="type-2">全文</label>
          <br/>
          <input type="radio" name="agree" value="0" id="agree-0" checked={this.state.type === 0} onChange={() => this.handleChange({type: 0})}/>
          <label htmlFor="agree-0">完全一致</label>{"　"}
          <input type="radio" name="agree" value="1" id="agree-1" checked={this.state.type === 1} onChange={() => this.handleChange({type: 1})}/>
          <label htmlFor="agree-1">部分一致</label>{"　"}
          <input type="radio" name="agree" value="2" id="agree-2" checked={this.state.type === 2} onChange={() => this.handleChange({type: 2})}/>
          <label htmlFor="agree-2">最小対語</label>
          <br/>
          <input type="radio" name="version" value="0" id="version-0" checked={this.state.version === 0} onChange={() => this.handleChange({version: 0})}/>
          <label htmlFor="version-0">5 代 5 期</label>{"　"}
          <input type="radio" name="version" value="2" id="version-2" checked={this.state.version === 2} onChange={() => this.handleChange({version: 2})}/>
          <label htmlFor="version-2">3 代 6 期</label>{"　"}
          <input type="radio" name="version" value="4" id="version-4" checked={this.state.version === 4} onChange={() => this.handleChange({version: 4})}/>
          <label htmlFor="version-4">3 代 4 期</label>{"　"}
          <input type="radio" name="version" value="3" id="version-3" checked={this.state.version === 3} onChange={() => this.handleChange({version: 3})}/>
          <label htmlFor="version-3">2 代 7 期</label>{"　"}
          <input type="radio" name="version" value="1" id="version-1" checked={this.state.version === 1} onChange={() => this.handleChange({version: 1})}/>
          <label htmlFor="version-1">1 代 2 期</label>
          <br/>
          <input type="checkbox" name="conversion" value="0" id="checkbox-conversion-0" defaultChecked={true}/>
          <label htmlFor="checkbox-conversion-0">正書法変換</label>{"　"}
          <input type="checkbox" name="random" value="1" id="random-1" checked={this.state.random} onChange={(event) => this.handleChange({random: event.target.checked})}/>
          <label htmlFor="random-1">結果シャッフル</label>
        </form>
      </Fragment>
    );
    return node;
  }

  private renderResult(): ReactNode {
    let wordNodes = this.state.result.words.map((word) => <WordPane word={word}/>);
    let node = (
      <Fragment>
        <h1>検索結果</h1>
        {wordNodes}
      </Fragment>
    );
    return node;
  }

  public render(): ReactNode {
    let node = (
      <Fragment>
        {this.renderForm()}
        {this.renderResult()}
      </Fragment>
    );
    return node;
  }

}


export class WordPane extends Component<{word: Word}, {}> {

  private renderHead(): ReactNode {
    let word = this.props.word;
    let node = (
      <div className="head">
        <span className="head-name">
          <span className="sans">{word.name.replace("~", "")}</span>
        </span>
        <span className="pronunciation">/{word.pronunciation}/</span>
        <span className="date">{word.date}</span>
        <span className="box">{word.sort}</span>
      </div>
    );
    return node;
  }

  private renderEquivalents(): ReactNode {
    let word = this.props.word;
    let innerNodes = word.equivalents.map((equivalent) => {
      let innerNode = (
        <Fragment>
          <span className="box">{equivalent.category}</span>
          {equivalent.names.join(", ")}
          <br/>
        </Fragment>
      );
      return innerNode;
    });
    let node = (
      <p className="equivalent">
        {innerNodes}
      </p>
    );
    return node;
  }

  private renderContents(): ReactNode {
    let word = this.props.word;
    let nodes = word.contents.map((content) => {
      let node = (
        <div className="explanation">
          <div className="kind">{content.type}:</div>
          <div className="content">{content.text}</div>
        </div>
      );
      return node;
    });
    return nodes;
  }

  private renderExamples(): ReactNode {
    let word = this.props.word;
    let innerNodes = word.examples.map((example) => {
      let innerNode = (
        <li>
          {example.shaleian}
          <ul><li>{example.japanese}</li></ul>
        </li>
      );
      return innerNode;
    });
    let node = (
      <ul className="conlang">
        {innerNodes}
      </ul>
    );
    return node;
  }

  private renderSynonyms(): ReactNode {
    let word = this.props.word;
    let innerNodes = word.synonyms.map((synonym) => synonym.names.join(", ")).join("; ");
    let node = (
      <p className="synonym">
        {innerNodes}
      </p>
    );
    return node;
  }

  private renderMain(): ReactNode {
    let word = this.props.word;
    let node = (
      <div className="result-wrapper">
        <div className="border"/>
        <div className="result">
          {word.equivalents.length > 0 && this.renderEquivalents()}
          {word.contents.length > 0 && this.renderContents()}
          {word.examples.length > 0 && this.renderExamples()}
          {word.synonyms.length > 0 && this.renderSynonyms()}
        </div>
      </div>
    );
    return node;
  }

  public render(): ReactNode {
    let node = (
      <Fragment>
        {this.renderHead()}
        {this.renderMain()}
      </Fragment>
    );
    return node;
  }

}


export class Executor {

  public prepare(): void {
    this.renderRoot();
  }

  private renderRoot(): void {
    render(<Root/>, document.getElementById("root"));
  }

}


let executor = new Executor();
window.addEventListener("load", () => {
  executor.prepare();
});