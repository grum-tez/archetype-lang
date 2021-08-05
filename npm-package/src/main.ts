var api = require("./api.bc.js");

export function version() {
  return api.version;
}

export function compile(src : string, settings : object = {}) {
  return api.compile()(src, settings).trim();
}

export function decompile(src : string, settings : object = {}) {
  return api.decompile()(src, settings).trim();
}

export function get_expr(data, settings : object = {}) {
  return api.getExpr()(data, settings).trim();
}

export function get_expr_type(data, type, settings : object = {}) {
  return api.getExprType()(data, type, settings).trim();
}

export function with_parameters(src, settings : object = {}) {
  return api.withParameters()(src, settings).trim();
}

export function show_entries(src, settings : object = {}) {
  return api.showEntries()(src, settings).trim();
}
