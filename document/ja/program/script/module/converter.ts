//

import {
  ReactElement
} from "react";
import htmlParser from "react-html-parser";


type StringConverterOptions = {
  version?: number,
  equivalentParen?: boolean,
  synonymAsterisk?: boolean
};


export class StringConverter {

  public static parse(string: string, options: StringConverterOptions = {}): Array<ReactElement> {
    let elements = htmlParser(StringConverter.convert(string, options));
    return elements;
  }

  public static convert(string: string, options: StringConverterOptions = {}): string {
    string = string.replace(/\bH(\d+)/g, (_, date) => {
      return `<span class=\"hairia\">${date}</span>`;
    });
    string = string.replace(/\/(.+?)\//g, (_, innerString) => {
      return `<i>${innerString}</i>`;
    });
    string = string.replace(/\{(.+?)\}|\[(.+?)\]/g, (_, ...innerStrings) => {
      let innerString = innerStrings[0] ?? innerStrings[1];
      let link = !!innerStrings[0];
      let version = options.version ?? 0;
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