import { Token, alt, apply, buildLexer, expectEOF, expectSingleResult, kmid, rep_sc, rule, seq, tok } from 'npm:typescript-parsec@0.3.4';

enum TokenKind {
  Quote,
  LBracket,
  RBracket,
  Whitespace,
  String,
}

const lexer = buildLexer([
  [true, /^"[^"]*"/g, TokenKind.String],
  [true, /^{/g, TokenKind.LBracket],
  [true, /^}/g, TokenKind.RBracket],
  [false, /^\s+/g, TokenKind.Whitespace],
]);

export interface SteamObject {
  [key: string]: string | SteamObject
}

type KeyValuePair = [string, string | SteamObject];

const KEY_VALUE = rule<TokenKind, KeyValuePair>();
const OBJECT = rule<TokenKind, SteamObject>();

function applyString(value: Token<TokenKind.String>): string {
  return value.text.slice(1, -1);
}

function applyObject(values: KeyValuePair[]): SteamObject {
  const value: SteamObject = {};
  for (const val of values) {
    value[val[0]] = val[1];
  }
  return value;
}

OBJECT.setPattern(
  apply(
    kmid(
      tok(TokenKind.LBracket),
      rep_sc(KEY_VALUE),
      tok(TokenKind.RBracket)
    ),
    applyObject
  )
)

KEY_VALUE.setPattern(
  seq(
    apply(tok(TokenKind.String), applyString),
    alt(
      apply(tok(TokenKind.String), applyString),
      OBJECT,
    )
  )
);


export interface LockFile {
  appId: number;
  depotId: number,
  name: string,
  branches: {
    [branch: string]: string
  },
  builds: {
    [buildId: string]: {
      manifestId: string,
      hash: string,
      version: string,
    }
  }
}

export const parseObject = (raw: string): SteamObject => {
  const token = lexer.parse(raw);
  return expectSingleResult(expectEOF(OBJECT.parse(token)));
};