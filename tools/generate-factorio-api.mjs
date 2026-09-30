// generate-factorio-api.mjs
// ============================================================================
// 从官方 Factorio API 数据（svizzini 扩展提取自 lua-api.factorio.com）生成
// 一份通用的 EmmyLua 注释库，普适所有 Factorio mod 开发。
//
// 输入：
//   classes.json  —— 全部 Lua* 运行时类（含继承展平后的成员）
//   defines.json  —— 全部 defines.* 枚举
// 输出（写入 outDir）：
//   globals.lua   —— 全局对象 game/script/storage/log 及类型别名
//   classes.lua   —— 所有 Lua* 类的 ---@class 定义与字段/方法
//   defines.lua   —— 所有 defines.* 嵌套表
//
// 运行：node generate-factorio-api.mjs <classes.json> <defines.json> <outDir>
// ============================================================================

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, dirname, basename } from 'node:path';

const [, , classesPath, definesPath, outDir] = process.argv;
if (!classesPath || !definesPath || !outDir) {
  console.error('usage: node generate-factorio-api.mjs <classes.json> <defines.json> <outDir>');
  process.exit(1);
}

const classes = JSON.parse(readFileSync(classesPath, 'utf8'));
const defines = JSON.parse(readFileSync(definesPath, 'utf8'));

// 中文文档库（由 factorio-zh-write 工作流生成）。可选：存在则用中文覆盖英文 doc。
// 格式：{ 类名: { doc: '类说明', members: { 成员名: '说明' } } }
let zhDocs = {};
const zhPath = new URL('./zh-docs.json', import.meta.url);
try {
  zhDocs = JSON.parse(readFileSync(zhPath, 'utf8'));
  console.log(`已加载中文文档库：${Object.keys(zhDocs).length} 个类`);
} catch {
  console.warn('未找到 zh-docs.json，将使用英文官方说明。');
}

// 取某类某成员的中文说明；取不到则回退英文。
function zhDoc(className, memberName) {
  const cls = zhDocs[className];
  if (!cls) return null;
  return cls.members && cls.members[memberName] ? cls.members[memberName] : null;
}
function zhClassDoc(className) {
  return zhDocs[className] && zhDocs[className].doc ? zhDocs[className].doc : null;
}

// 参数字典（参数说明去重后按 id 索引的中文翻译）
let paramZh = {};
const paramZhPath = new URL('./param-zh.json', import.meta.url);
try {
  paramZh = JSON.parse(readFileSync(paramZhPath, 'utf8'));
  console.log(`已加载参数字典：${Object.keys(paramZh).length} 条`);
} catch {
  console.warn('未找到 param-zh.json，参数说明将保留英文。');
}

// 把英文参数说明映射为中文：先查字典，回退原文。
function zhParamDoc(englishDoc) {
  if (!englishDoc) return '';
  const key = String(englishDoc).replace(/\s+/g, ' ').trim();
  return paramZh[key] !== undefined ? paramZh[key] : englishDoc;
}

// 从“参数名 :: 类型（可选）：描述”里剥离前缀，只保留真正的描述文字。
// 找不到描述分隔符（：或 : ）时返回 ''（该参数没有说明）。
function paramDescription(zhText) {
  if (!zhText) return '';
  // 先剥离 markdown 链接 [uint](url) -> uint
  const t = String(zhText).replace(/\[([^\]]+)\]\([^)]*\)/g, '$1');
  // 找描述冒号：优先全角“：”；否则找第一个不属于“::”的英文冒号。
  let cut = t.indexOf('：');
  if (cut === -1) {
    for (let i = 1; i < t.length; i++) {
      if (t[i] === ':' && t[i - 1] !== ':' && t[i + 1] !== ':') { cut = i; break; }
    }
  }
  if (cut === -1) return ''; // 无描述
  return t.slice(cut + 1).replace(/^[\s:\u3000]+/, '').trim();
}

// 根据返回类型推断一个语义化的返回变量名，供 ---@return 类型 名称 使用。
function returnNameFor(retRaw) {
  const s = normalizeType(String(retRaw || '')).replace(/\[\]/g, '');
  const lower = s.toLowerCase();
  if (/or/.test(lower)) return 'result';
  if (lower.includes('boolean')) return 'ok';
  if (lower.includes('uint') || lower.includes('int') || lower.includes('number') || lower.includes('double') || lower.includes('float')) return 'count';
  if (lower.includes('string')) return 'result';
  if (lower.includes('table')) return 'result';
  const m = s.match(/(Lua\w+)/);
  if (m) return m[1].replace(/^Lua/, '').replace(/^./, c => c.toLowerCase());
  return 'result';
}

// ---------------------------------------------------------------------------
// 类型字符串 -> EmmyLua 类型
// ---------------------------------------------------------------------------

// 常见 Factorio 类型名 -> EmmyLua
const PRIMITIVE = {
  boolean: 'boolean',
  bool: 'boolean',
  uint: 'integer',
  int: 'integer',
  int8: 'integer',
  uint8: 'integer',
  uint16: 'integer',
  int16: 'integer',
  uint32: 'integer',
  int32: 'integer',
  uint64: 'integer',
  int64: 'integer',
  double: 'number',
  float: 'number',
  real: 'number',
  string: 'string',
  char: 'string',
  table: 'table',
  function: 'fun(...)',
  'function()': 'fun()',
  any: 'any',
  Any: 'any',
  Anything: 'any',
  object: 'table',
};

// 把原始类型串归一化：统一把“字典箭头”替换为标记符号，便于按分隔解析。
function normalizeType(raw) {
  return String(raw)
    .replace(/\u2192/g, '>>') // →
    .replace(/\u2190/g, '<<'); // ←
}

// 将单个类型 token 映射为 EmmyLua 类型（只处理最简单 token，复合类型见 toEmmy）
function mapAtom(tok) {
  const t = tok.trim();
  if (t === '') return 'any';
  if (t === 'nil') return 'nil';
  if (PRIMITIVE[t] !== undefined) return PRIMITIVE[t];
  if (t.endsWith('[]')) return mapAtom(t.slice(0, -2)) + '[]';
  if (/^function\(.*\)$/.test(t)) return t.replace(/^function/, 'fun'); // function(Event) -> fun(Event)
  if (/^Lua\w+$/.test(t) || /^Lua\w+ or /.test(t)) return t; // 类引用，原样
  if (/^defines\.\w+/.test(t)) return t; // defines.* 枚举，原样保留
  // 概念类型（Concept）统一视为 table
  return 'table';
}

// 复合类型 -> EmmyLua
function toEmmy(original) {
  const s = normalizeType(original).trim();
  if (!s) return 'any';

  // 数组
  if (s.startsWith('array of ')) {
    const inner = s.slice('array of '.length);
    return toEmmy(inner) + '[]';
  }
  // 字典：dictionary/custom dictionary K -> V
  const dictMatch = s.match(/^(?:custom )?dictionary\s+(.+?)\s*>>\s*(.+)$/);
  if (dictMatch) {
    const k = toEmmy(dictMatch[1]);
    const v = toEmmy(dictMatch[2]);
    return `table<${k}, ${v}>`;
  }
  // or 复合
  if (s.includes(' or ')) {
    const parts = s.split(' or ').map((p) => toEmmy(p.trim()));
    return [...new Set(parts)].join(' | ');
  }
  // 单 token
  return mapAtom(s);
}

// ---------------------------------------------------------------------------
// 生成 globals.lua（全局 + 别名）
// ---------------------------------------------------------------------------

// Lua 保留字：用作 @param/@field 标识符会报错，需要改名。
const RESERVED = new Set([
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
  'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then',
  'true', 'until', 'while',
]);

// 纯类型名用作参数名/返回名时（如 uint/table/string），加下划线避免歧义。
const PRIMITIVE_NAME = new Set([
  'uint', 'int', 'string', 'boolean', 'bool', 'table', 'double', 'float',
  'number', 'function', 'object', 'any', 'real', 'char', 'uint8', 'int8',
  'uint16', 'int16', 'uint32', 'int32', 'uint64', 'int64', 'nil',
]);

// 保留字 / 非法标识符 / 纯类型名 -> 加下划线前缀，避免 EmmyLua 报错或歧义。
function safeIdent(name) {
  const n = String(name);
  if (!n) return '_arg';
  if (RESERVED.has(n) || PRIMITIVE_NAME.has(n)) return '_' + n;
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(n)) return '_' + n.replace(/[^A-Za-z0-9_]/g, '_');
  return n;
}

// 把官方 doc（markdown）压成一行、去掉 markdown 链接/强调，作为内联说明。
function flattenDoc(doc) {
  if (!doc) return '';
  return String(doc)
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1') // [uint](url) -> uint
    .replace(/[`*]/g, '')                     // 去掉反引号和星号
    .replace(/\s+/g, ' ')                     // 多空白 -> 单空格
    .trim();
}

// ---------------------------------------------------------------------------
// 缺失的 LuaBootstrap（script）方法 —— 官方数据源未包含，手动补齐。
// 仅补当前 Factorio 确实存在的两个方法；其余（get_global/set_global/
// get_remote_interface/raise_remote_interface/get_mod_setting）不属于现行
// script.* API（分别被 storage/remote/settings 取代或已移除），不予伪造。
// ---------------------------------------------------------------------------

const BOOTSTRAP_EXTRA = {
  register_on_object_destroyed: {
    type: 'function',
    doc: '注册一个对象（实体/GUI 元素等）的销毁监听。当该对象被销毁时触发 on_object_destroyed 事件。通常配合 script.on_event(defines.events.on_object_destroyed) 使用，在事件中通过 event.register_number 判断是哪个对象。',
    returns: [
      { type: 'uint64', name: 'register_number', doc: '注册号。用于在 on_object_destroyed 事件中标识该对象。' },
      { type: 'uint64', name: 'useful_id', doc: '对象的有用标识符；若对象没有则为 0。此标识符与对象类型相关，例如火车是 LuaTrain::id 的值。' },
      { type: 'defines.target_type', name: 'target_type', doc: '目标对象的类型。' },
    ],
    args: {
      object: { name: 'object', type: 'LuaEntity or LuaGuiElement or LuaEquipmentGrid', doc: '要监听销毁的对象' },
    },
  },
  on_shutdown: {
    type: 'function',
    doc: '注册一个函数，在游戏正常关闭时调用。',
    returns: null,
    args: {
      handler: { name: 'handler', type: 'function()', doc: '关闭时执行的回调' },
    },
  },
};

// 把官方 doc 转成多行 `---` 注释（方法/类的悬停说明）。
function docLines(doc) {
  if (!doc) return [];
  const text = String(doc)
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/[`*]/g, '')
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean);
  return text.map((l) => `--- ${l}`);
}

function genGlobals() {
  const L = [];
  L.push('-- globals.lua');
  L.push('-- 全局对象声明 + 常用概念类型别名。');
  L.push('-- 本文件仅类型注释，不会被 Factorio 加载执行。');
  L.push('');
  L.push('---@class LuaGameScript');
  L.push('---@class LuaBootstrap');
  L.push('');
  L.push('---@alias Position { x: number, y: number }');
  L.push('---@alias Area { [integer]: Position }');
  L.push('---@alias BoundingBox { left_top: Position, right_bottom: Position }');
  L.push('---@alias LocalisedString string | string[] | { [integer]: any }');
  L.push('---@alias SignalID { name: string, type: string, quality?: string }');
  L.push('---@alias SpritePath string');
  L.push('');
  L.push('---@type LuaGameScript');
  L.push('game = {}');
  L.push('');
  L.push('---@type LuaBootstrap');
  L.push('script = {}');
  L.push('');
  L.push('---@type table<string, any>');
  L.push('storage = {}');
  L.push('');
  L.push('---@type fun(message: string)');
  L.push('log = function(message) end');
  L.push('');
  L.push('---@type fun(message: any)');
  L.push('print = function(message) end');
  L.push('');
  return L.join('\n');
}

// ---------------------------------------------------------------------------
// 生成 classes.lua
// ---------------------------------------------------------------------------

function isMethod(member) {
  return member.type === 'function' || member.type === 'function()' || /^function\(/.test(member.type || '');
}

function optionalSuffix(member) {
  const doc = String(member.doc || '');
  const nm = String(member.name || '');
  return /\(optional\)/.test(doc) || nm.endsWith('?') ? '?' : '';
}

function genClass(name, cls) {
  const L = [];
  const classDoc = zhClassDoc(name) || cls.doc;   // 优先中文类说明
  L.push(...docLines(classDoc));                  // 类的说明
  L.push(`---@class ${name}`);
  // 合并官方成员 + 手动补全的缺失成员（仅 LuaBootstrap）
  const merged = { ...(cls.properties || {}) };
  if (name === 'LuaBootstrap') {
    for (const [mn, md] of Object.entries(BOOTSTRAP_EXTRA)) {
      merged[mn] = { name: mn, ...md };
    }
  }
  // 先输出字段（非函数）
  for (const mem of Object.values(merged)) {
    if (isMethod(mem)) continue;
    const emmy = toEmmy(mem.type || 'Any');
    const opt = mem.type && String(mem.type).includes('nil') ? '?' : '';
    const mode = mem.mode === '[R]' ? ' (只读)' : mem.mode === '[W]' ? ' (只写)' : '';
    const desc = flattenDoc(zhDoc(name, mem.name) || mem.doc);
    L.push(`---@field ${safeIdent(mem.name)} ${emmy}${opt}${mode}${desc ? ' ' + desc : ''}`);
  }
  L.push(`${name} = {}`);
  L.push('');
  // 再输出方法
  for (const mem of Object.values(merged)) {
    if (!isMethod(mem)) continue;
    L.push(...docLines(zhDoc(name, mem.name) || mem.doc));  // 方法的说明（中文优先）
    // 返回值：可为单个类型字符串，或 [{ type, name?, doc? }, ...] 的多返回值数组。
    const retDefs = Array.isArray(mem.returns)
      ? mem.returns
      : (mem.returns ? [{ type: mem.returns }] : []);
    for (const rd of retDefs) {
      const ret = toEmmy(rd.type || 'Any');
      const rname = rd.name || returnNameFor(rd.type);
      const rdesc = rd.doc ? ' ' + flattenDoc(rd.doc) : '';
      L.push(`---@return ${ret} ${rname}${rdesc}`);
    }
    const args = mem.args || {};
    const paramNames = [];
    for (const a of Object.values(args)) {
      const nm = safeIdent(a.name);
      if (a.name === 'undefined' || !nm) continue;
      paramNames.push(nm);
      const emmy = toEmmy(a.type || 'Any');
      const opt = optionalSuffix(a);
      const desc = paramDescription(zhParamDoc(a.doc));
      L.push(`---@param ${nm} ${emmy}${opt}${desc ? ' ' + desc : ''}`);
    }
    // 用真实参数名而非 ...，让 EmmyLua 签名提示能显示参数列表。
    const sig = paramNames.length ? paramNames.join(', ') : '...';
    L.push(`function ${name}:${safeIdent(mem.name)}(${sig}) end`);
    L.push('');
  }
  return L.join('\n');
}

function genClasses() {
  const L = [];
  L.push('-- classes.lua');
  L.push('-- 全部 Factorio 运行时 Lua* 类（由官方 API 数据生成）。');
  L.push('-- 成员已含继承展平；方法用 :name(...) 定义以支持自动补全与跳转。');
  L.push('-- 每个类/字段/方法均带官方文档说明，悬停即可查看用法。');
  L.push('');
  const names = Object.keys(classes).sort();
  for (const name of names) {
    L.push(genClass(name, classes[name]));
  }
  return L.join('\n');
}

// ---------------------------------------------------------------------------
// 生成 defines.lua
// ---------------------------------------------------------------------------

function genDefinesTable(prefix, props, L, indent) {
  if (!props) return;
  const pad = '  '.repeat(indent);
  L.push(`${pad}---@type table`);
  for (const key of Object.keys(props)) {
    const v = props[key];
    if (v && v.properties) {
      // 嵌套 define 组
      L.push(`${pad}${prefix}${key} = {}`);
      genDefinesTable(prefix + key + '.', v.properties, L, indent + 1);
    } else {
      // 叶子 define 值
      L.push(`${pad}${prefix}${key} = nil`);
    }
  }
}

function genDefines() {
  const L = [];
  L.push('-- defines.lua');
  L.push('-- 全部 defines.* 枚举（由官方 API 数据生成）。');
  L.push('-- 叶子值以 nil 占位；嵌套组递归展开，供 EmmyLua 识别字段名。');
  L.push('');
  L.push('---@type table');
  L.push('defines = {}');
  L.push('');
  genDefinesTable('defines.', defines, L, 0);
  return L.join('\n');
}

// ---------------------------------------------------------------------------
// 写文件
// ---------------------------------------------------------------------------

mkdirSync(outDir, { recursive: true });
const files = {
  'globals.lua': genGlobals(),
  'classes.lua': genClasses(),
  'defines.lua': genDefines(),
};
for (const [f, content] of Object.entries(files)) {
  const p = join(outDir, f);
  writeFileSync(p, content, 'utf8');
  console.log(`wrote ${p} (${content.split('\n').length} lines)`);
}
console.log('done.');
