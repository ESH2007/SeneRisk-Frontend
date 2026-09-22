// Genera assets/maps/light_v4.json: estilo Protomaps v4 "light" adaptado a lo que
// soporta vector_tile_renderer 6.x (sin `format`, `in` solo en sintaxis legacy, sin `length`).
// Uso: npm i @protomaps/basemaps && node gen_style.mjs > ../../frontend/assets/maps/light_v4.json
import { layers, namedFlavor } from "@protomaps/basemaps";

const isArr = Array.isArray;
// ["in", ["get", k], ["literal", [...]]] -> ["in", k, ...]
function fix(e) {
  if (!isArr(e)) return e;
  if ((e[0] === "in" || e[0] === "!in") && isArr(e[1]) && e[1][0] === "get" && isArr(e[2]) && e[2][0] === "literal") {
    return [e[0], e[1][1], ...e[2][1]];
  }
  // [">=", ["zoom"], [...]] no se soporta como filtro: se deja al minzoom de la capa
  if (e[0] === ">=" && isArr(e[1]) && e[1][0] === "zoom") return true;
  return e.map(fix);
}
const usesLength = (e) => isArr(e) && (e[0] === "length" || e.some(usesLength));

const ls = layers("protomaps", namedFlavor("light"), { lang: "es" })
  // sin sprites empaquetados: fuera escudos viales (usan `length`) y flechas de sentido único
  .filter((l) => !usesLength(l.filter) && !usesLength(l.layout?.["icon-image"]) && l.id !== "roads_oneway")
  .map((l) => {
    l.filter = fix(l.filter);
    if (l.paint) for (const k in l.paint) l.paint[k] = fix(l.paint[k]);
    if (l.layout) for (const k in l.layout) l.layout[k] = fix(l.layout[k]);
    if (l.type === "symbol" && l.layout?.["text-field"]) {
      l.layout["text-field"] = ["coalesce", ["get", "name:es"], ["get", "name"]];
      l.layout["text-font"] = ["Noto Sans Regular"];
    }
    return l;
  });

const style = { version: 8, name: "protomaps-light-v4", id: "protomaps-light-v4",
  sources: { protomaps: { type: "vector", url: "" } }, layers: ls };
console.log(JSON.stringify(style, null, 1));
