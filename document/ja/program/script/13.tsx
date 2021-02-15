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
  StringConverter
} from "./module/converter";
import {
  ExecutorBase
} from "./module/executor";
import {
  RootBase
} from "./module/search";


type Equivalent = {category: string, names: Array<string>};
type Content = {type: string | null, text: string};
type Example = {type: "例文", shaleian: string, japanese: string};
type Synonym = {category: string | null, names: Array<string>};


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


type RawResult = {words: Array<object>, suggestions: Array<object>, hitSize: number};
type Result = {words: Array<Word>, suggestions: Array<Suggestion>, hitSize: number};

type RootState = {
  search: string,
  mode: number,
  type: number,
  version: number,
  random: boolean,
  page: number,
  result: Result,
  errorMessage: string | null
};


export class Root extends RootBase<{}, RootState> {

  public state: RootState = {
    search: "",
    mode: 3,
    type: 3,
    page: 0,
    version: 0,
    random: false,
    result: {words: [], suggestions: [], hitSize: 0},
    errorMessage: null
  };

  protected async updateResultsBase(): Promise<void> {
    let response = await axios.get("../../program/interface/3.cgi?mode=search&" + this.serializeQueryBase(), {validateStatus: () => true});
    if (response.status === 200 && !("error" in response.data)) {
      let rawResult = response.data as RawResult;
      let words = rawResult.words.map((word) => new Word(word));
      let suggestions = rawResult.suggestions.map((suggestion) => new Suggestion(suggestion));
      let hitSize = rawResult.hitSize;
      let errorMessage = null;
      let result = {words, suggestions, hitSize};
      this.setState({result, errorMessage});
    } else {
      let errorMessage = response.data.message;
      let result = {words: [], suggestions: [], hitSize: 0};
      this.setState({result, errorMessage});
    }
  }

  protected deserializeQueryBase(): RootState {
    let query = queryParser.parse(window.location.search);
    let nextState = {} as any;
    nextState.search = (typeof query["search"] === "string") ? query["search"] : "";
    nextState.mode = (typeof query["type"] === "string") ? +query["type"] : 3;
    nextState.type = (typeof query["agree"] === "string") ? +query["agree"] : 3;
    nextState.version = (typeof query["version"] === "string") ? +query["version"] : 0;
    nextState.random = (typeof query["random"] === "string") ? query["random"] === "1" : false;
    nextState.page = (typeof query["page"] === "string") ? +query["page"] : 0;
    return nextState;
  }

  protected serializeQueryBase(overriddenState?: Partial<RootState>): string {
    let query = {} as any;
    let state = Object.assign({}, this.state, overriddenState);
    query["search"] = state.search;
    query["type"] = state.mode;
    query["agree"] = state.type;
    query["version"] = state.version;
    query["random"] = +state.random;
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
          <input type="radio" name="type" value="3" id="type-3" checked={this.state.mode === 3} onChange={() => this.handleSearchChange({mode: 3})}/>
          <label htmlFor="type-3">単語<span className="japanese">＋</span>訳語</label>{"　"}
          <input type="radio" name="type" value="0" id="type-0" checked={this.state.mode === 0} onChange={() => this.handleSearchChange({mode: 0})}/>
          <label htmlFor="type-0">単語</label>{"　"}
          <input type="radio" name="type" value="1" id="type-1" checked={this.state.mode === 1} onChange={() => this.handleSearchChange({mode: 1})}/>
          <label htmlFor="type-1">訳語</label>{"　"}
          <input type="radio" name="type" value="2" id="type-2" checked={this.state.mode === 2} onChange={() => this.handleSearchChange({mode: 2})}/>
          <label htmlFor="type-2">全文</label>
          <br/>
          <input type="radio" name="agree" value="3" id="agree-3" checked={this.state.type === 3} onChange={() => this.handleSearchChange({type: 3})}/>
          <label htmlFor="agree-3">前方一致</label>{"　"}
          <input type="radio" name="agree" value="0" id="agree-0" checked={this.state.type === 0} onChange={() => this.handleSearchChange({type: 0})}/>
          <label htmlFor="agree-0">完全一致</label>{"　"}
          <input type="radio" name="agree" value="1" id="agree-1" checked={this.state.type === 1} onChange={() => this.handleSearchChange({type: 1})}/>
          <label htmlFor="agree-1">正規表現</label>{"　"}
          <input type="radio" name="agree" value="2" id="agree-2" checked={this.state.type === 2} onChange={() => this.handleSearchChange({type: 2})}/>
          <label htmlFor="agree-2">最小対語</label>
          <br/>
          <input type="radio" name="version" value="0" id="version-0" checked={this.state.version === 0} onChange={() => this.handleSearchChange({version: 0})}/>
          <label htmlFor="version-0">5 代 5 期</label>{"　"}
          <input type="radio" name="version" value="2" id="version-2" checked={this.state.version === 2} onChange={() => this.handleSearchChange({version: 2})}/>
          <label htmlFor="version-2">3 代 6 期</label>{"　"}
          <input type="radio" name="version" value="4" id="version-4" checked={this.state.version === 4} onChange={() => this.handleSearchChange({version: 4})}/>
          <label htmlFor="version-4">3 代 4 期</label>{"　"}
          <input type="radio" name="version" value="3" id="version-3" checked={this.state.version === 3} onChange={() => this.handleSearchChange({version: 3})}/>
          <label htmlFor="version-3">2 代 7 期</label>{"　"}
          <input type="radio" name="version" value="1" id="version-1" checked={this.state.version === 1} onChange={() => this.handleSearchChange({version: 1})}/>
          <label htmlFor="version-1">1 代 2 期</label>
          <br/>
          <input type="checkbox" name="random" value="1" id="random-1" checked={this.state.random} onChange={(event) => this.handleSearchChange({random: event.target.checked})}/>
          <label htmlFor="random-1">結果シャッフル</label>
        </form>
      </Fragment>
    );
    return node;
  }

  private renderResult(): ReactNode {
    let result = this.state.result;
    let version = this.state.version;
    let wordNodes = result.words.map((word, index) => {
      return <WordPane word={word} version={version} key={index}/>;
    });
    let suggestionNodes = result.suggestions.map((suggestion, index) => {
      return <SuggestionPane suggestion={suggestion} version={version} key={index}/>;
    });
    let suggestionNode = (result.suggestions.length > 0) && (
      <ul className="suggest">
        {suggestionNodes}
      </ul>
    );
    let node = (
      <Fragment>
        <h1>検索結果</h1>
        {suggestionNode}
        {wordNodes}
      </Fragment>
    );
    return node;
  }

  private renderOverview(): ReactNode {
    let node = (
      <Fragment>
        <h1>概要</h1>
        <p>
          シャレイア語の公式オンライン辞典です。
          辞典の見方については<a href="../document/17.html">こちら</a>をご覧ください。
        </p>
      </Fragment>
    );
    return node;
  }

  public render(): ReactNode {
    let resultNode = (() => {
      if (this.state.errorMessage === null) {
        if (this.state.search === "") {
          return this.renderOverview();
        } else {
          return <Fragment>{this.renderResult()}{this.renderNumber(30)}</Fragment>;
        }
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


export class WordPane extends Component<{word: Word, version: number}> {

  private renderHead(): ReactNode {
    let word = this.props.word;
    let pronunciationNode = (word.pronunciation !== null) && (
      <span className="pronunciation">/{word.pronunciation}/</span>
    );
    let sortNode = (word.sort !== null && word.sort.match(/^\s*$/) === null) && (
      <span className="box">{word.sort}</span>
    );
    let node = (
      <div className="head">
        <span className="head-name">
          <span className="sans">{word.name.replace("~", "")}</span>
        </span>
        {pronunciationNode}
        {sortNode}
        <span className="date">{word.date}</span>
      </div>
    );
    return node;
  }

  private renderEquivalents(): ReactNode {
    let word = this.props.word;
    let version = this.props.version;
    let innerNodes = word.equivalents.map((equivalent, index) => {
      let innerNode = (
        <Fragment key={index}>
          <span className="box">{equivalent.category}</span>
          {StringConverter.parse(equivalent.names.join(", "), {version, equivalentParen: true})}
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
    let version = this.props.version;
    let nodes = word.contents.map((content, index) => {
      let node = (
        <div className="explanation" key={index}>
          <div className="kind">{content.type}:</div>
          <div className="content">{StringConverter.parse(content.text, {version})}</div>
        </div>
      );
      return node;
    });
    return nodes;
  }

  private renderExamples(): ReactNode {
    let word = this.props.word;
    let version = this.props.version;
    let innerNodes = word.examples.map((example, index) => {
      let innerNode = (
        <li key={index}>
          {StringConverter.parse(example.shaleian, {version})}
          <ul><li>{StringConverter.parse(example.japanese, {version})}</li></ul>
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
    let version = this.props.version;
    let innerNodes = word.synonyms.map((synonym, index) => {
      let string = synonym.names.join(", ");
      let innerNode = (
        <div className="synonym" key={index}>
          <span className="box">{synonym.category}</span>
          {StringConverter.parse(string, {version, synonymAsterisk: true})}
        </div>
      );
      return innerNode;
    });
    let node = (
      <div className="synonym-wrapper">
        {innerNodes}
      </div>
    );
    return node;
  }

  private renderBody(): ReactNode {
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
        {this.renderBody()}
      </Fragment>
    );
    return node;
  }

}


export class SuggestionPane extends Component<{suggestion: Suggestion, version: number}> {

  public render(): ReactNode {
    let suggestion = this.props.suggestion;
    let url = window.location.origin + window.location.pathname;
    let href = `${url}?search=${encodeURIComponent(suggestion.name)}&type=0&agree=0&version=${this.props.version}`;
    let node = (
      <li>
        {suggestion.explanation}
        {" → "}
        <a className="sans" href={href}>{suggestion.name}</a>
        {" ?"}
      </li>
    );
    return node;
  }

}


ExecutorBase.addLoadListener(() => {
  render(<Root/>, document.getElementById("root"));
});