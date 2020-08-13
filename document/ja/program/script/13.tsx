//

import axios from "axios";
import {
  debounce as lodashDebounce
} from "lodash";
import * as queryParser from "query-string";
import * as react from "react";
import {
  Component,
  Fragment,
  ReactNode,
  SyntheticEvent
} from "react";
import {
  render
} from "react-dom";
import htmlParser from "react-html-parser";


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

function debounce(duration: number): MethodDecorator {
  let decorator = function (target: object, name: string | symbol, descriptor: PropertyDescriptor): PropertyDescriptor {
    descriptor.value = lodashDebounce(descriptor.value, duration);
    return descriptor;
  };
  return decorator;
}


export class Root extends Component<{}, RootState> {

  public state: RootState = {
    search: "",
    mode: 3,
    type: 0,
    page: 0,
    version: 0,
    random: false,
    result: {words: [], suggestions: [], hitSize: 0},
    errorMessage: null
  };

  public constructor(props: {}) {
    super(props);
    this.serializeQuery(true);
  }

  public async componentDidMount(): Promise<void> {
    await this.updateResultsImmediately(false);
  }

  private async updateResultsImmediately(deserialize: boolean = true): Promise<void> {
    let response = await axios.get("../../program/interface/3.cgi?mode=search&" + this.deserializeQueryBase(), {validateStatus: () => true});
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
    if (deserialize) {
      this.deserializeQuery();
    }
  }

  @debounce(500)
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
    let url = window.location.origin + window.location.pathname;
    window.history.replaceState({}, document.title, url + "?" + queryString);
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

  private deserializeQueryBase(overriddenState?: Partial<RootState>): string {
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

  private handleSearchChange(nextState: Partial<RootState>, event?: SyntheticEvent): void {
    let page = 0;
    let anyNextState = nextState as any;
    event?.preventDefault();
    this.setState({...anyNextState, page}, () => {
      this.updateResults();
    });
  }

  private handlePageChange(page: number, event?: SyntheticEvent): void {
    event?.preventDefault();
    this.setState({page}, async () => {
      window.scrollTo(0, 0);
      await this.updateResultsImmediately(true);
    });
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
          <input type="radio" name="agree" value="0" id="agree-0" checked={this.state.type === 0} onChange={() => this.handleSearchChange({type: 0})}/>
          <label htmlFor="agree-0">完全一致</label>{"　"}
          <input type="radio" name="agree" value="1" id="agree-1" checked={this.state.type === 1} onChange={() => this.handleSearchChange({type: 1})}/>
          <label htmlFor="agree-1">部分一致</label>{"　"}
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

  private renderErrorMessage(): ReactNode {
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

  private renderNumber(): ReactNode {
    let page = this.state.page;
    let hitSize = this.state.result.hitSize;
    let url = window.location.origin + window.location.pathname;
    let leftArrowNode = (() => {
      if (page > 0) {
        let queryString = this.deserializeQueryBase({page: page - 1});
        return <a className="left-arrow" href={url + "?" + queryString} onClick={(event) => this.handlePageChange(page - 1, event)}/>;
      } else {
        return <span className="left-arrow invalid"/>;
      }
    })();
    let rightArrowNode = (() => {
      if (page * 30 + 30 < hitSize) {
        let queryString = this.deserializeQueryBase({page: page + 1});
        return <a className="right-arrow" href={url + "?" + queryString} onClick={(event) => this.handlePageChange(page + 1, event)}/>;
      } else {
        return <span className="right-arrow invalid"/>;
      }
    })();
    let fractionNode = (
      <div className="fraction">
        <div className="page">{Math.min(page * 30 + 1, hitSize)} ～ {Math.min(page * 30 + 30, hitSize)}</div>
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

  public render(): ReactNode {
    let resultNode = (() => {
      if (this.state.errorMessage === null) {
        return <Fragment>{this.renderResult()}{this.renderNumber()}</Fragment>;
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
    let node = (
      <div className="head">
        <span className="head-name">
          <span className="sans">{word.name.replace("~", "")}</span>
        </span>
        {pronunciationNode}
        <span className="date">{word.date}</span>
        <span className="box">{word.sort}</span>
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
          {htmlParser(StringConverter.convert(equivalent.names.join(", "), version, {equivalentParen: true}))}
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
          <div className="content">{htmlParser(StringConverter.convert(content.text, version))}</div>
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
          {htmlParser(StringConverter.convert(example.shaleian, version))}
          <ul><li>{htmlParser(StringConverter.convert(example.japanese, version))}</li></ul>
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
    let string = word.synonyms.map((synonym) => synonym.names.join(", ")).join("; ");
    let innerNodes = htmlParser(StringConverter.convert(string, version, {synonymAsterisk: true}));
    let node = (
      <p className="synonym">
        {innerNodes}
      </p>
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
    let href = `${url}?search=${suggestion.name}&type=0&agree=0&version=${this.props.version}`;
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


type StringConverterOptions = {
  equivalentParen?: boolean,
  synonymAsterisk?: boolean
};


export class StringConverter {

  public static convert(string: string, version: number, options: StringConverterOptions = {}): string {
    string = string.replace(/\bH(\d+)/g, (_, date) => {
      return `<span class=\"hairia\">${date}</span>`;
    });
    string = string.replace(/\/(.+?)\//g, (_, innerString) => {
      return `<i>${innerString}</i>`;
    });
    string = string.replace(/\{(.+?)\}|\[(.+?)\]/g, (_, ...innerStrings) => {
      let innerString = innerStrings[0] ?? innerStrings[1];
      let link = !!innerStrings[0];
      return StringConverter.convertShaleian(innerString, link, version);
    });
    if (options.equivalentParen) {
      string = string.replace(/\((.+?)\)\s*/g, (_, innerString) => {
        return `<span class=\"small\">${innerString}</span>`;
      });
    }
    if (options.synonymAsterisk) {
      string = string.replace(/\*/g, (_) => {
        return `<span class=\"asterisk\">†</span>`;
      });
    }
    string = StringConverter.convertPunctuation(string);
    return string;
  }

  public static convertPunctuation(string: string): string {
    string = string.replace(/、/g, "、 ");
    string = string.replace(/。/g, "。 ");
    string = string.replace(/「/g, " 「");
    string = string.replace(/」/g, "」 ");
    string = string.replace(/」 、/g, "」、");
    string = string.replace(/」 。/g, "」。");
    string = string.replace(/『/g, " 『");
    string = string.replace(/』/g, "』 ");
    string = string.replace(/』 、/g, "』、");
    string = string.replace(/』 。/g, "』。");
    string = string.replace(/〈/g, " 〈");
    string = string.replace(/〉/g, "〉 ");
    string = string.replace(/〉 、/g, "〉、");
    string = string.replace(/〉 。/g, "〉。");
    string = string.replace(/…/g, "<span class=\"japanese\">…</span>");
    string = string.replace(/  /g, " ");
    string = string.replace(/^\s*/g, "");
    return string;
  }

  public static convertShaleian(string: string, link: boolean, version: number): string {
    let url = window.location.origin + window.location.pathname;
    let leftNames = ["s'", "al'", "ac'", "di'"];
    if (link) {
      string = "%" + string.replace(/\s+/g, "% %").replace(/\-/g, "%-%") + "%";
      string = string.replace(/%([\"\[«…]*)(.*?)([!\?\.,\"\]»…]*)%/g, (_, left, matchedName, right) => {
        let modifiedName = matchedName.replace(/<\/?\w+>/g, "");
        let innerMatch = matchedName.match(/(.+)'(.+)/);
        if (innerMatch !== null) {
          let abbreviationLeft = innerMatch[1];
          let abbreviationRight = innerMatch[2];
          let modifiedLeft = abbreviationLeft.replace(/<\/?\w+>/g, "");
          let modifiedRight = abbreviationRight.replace(/<\/?\w+>/g, "");
          if (leftNames.includes(`${modifiedLeft}'`)) {
            let html = left;
            if (abbreviationLeft.match(/^[0-9:]$/)) {
              html += abbreviationLeft + "'";
            } else {
              html += `<a href=\"${url}?search=${modifiedLeft}'&amp;type=0&amp;agree=0&amp;version=${version}\" rel=\"nofollow\">${abbreviationLeft}'</a>`;
            }
            if (abbreviationRight.match(/^[0-9:]$/)) {
              html += abbreviationRight;
            } else {
              html += `<a href=\"${url}?search=${modifiedRight}&amp;type=0&amp;agree=0&amp;version=${version}\" rel=\"nofollow\">${abbreviationRight}</a>`;
            }
            html += right;
            return html;
          } else {
            let html = left;
            if (abbreviationLeft.match(/^[0-9:]$/)) {
              html += abbreviationLeft;
            } else {
              html += `<a href=\"${url}?search=${modifiedLeft}&amp;type=0&amp;agree=0&amp;version=${version}\" rel=\"nofollow\">${abbreviationLeft}</a>`;
            }
            if (abbreviationRight.match(/^[0-9:]$/)) {
              html += "'" + abbreviationRight;
            } else {
              html += `<a href=\"${url}?search='${modifiedRight}&amp;type=0&amp;agree=0&amp;version=${version}\" rel=\"nofollow\">'${abbreviationRight}</a>`;
            }
            html += right;
            return html;
          }
        } else {
          let html = left;
          if (matchedName.match(/^[0-9:]$|^ʻ|^—$/)) {
            html += matchedName;
          } else {
            html += `<a href=\"${url}?search=${modifiedName}&amp;type=0&amp;agree=0&amp;version=${version}\" rel=\"nofollow\">${matchedName}</a>`;
          }
          html += right;
          return html;
        }
      });
      return `<span class=\"sans\">${string}</span>`;
    } else {
      return `<span class=\"sans\">${string}</span>`;
    }
  }

}


window.addEventListener("load", () => {
  render(<Root/>, document.getElementById("root"));
});