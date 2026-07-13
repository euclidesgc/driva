/* @ds-bundle: {"format":3,"namespace":"DrivaDesignSystem_5934aa","components":[{"name":"BlockRow","sourcePath":"components/builder/BlockRow.jsx"},{"name":"PropertyRow","sourcePath":"components/builder/PropertyRow.jsx"},{"name":"StageBadge","sourcePath":"components/builder/StageBadge.jsx"},{"name":"StateChip","sourcePath":"components/builder/StateChip.jsx"},{"name":"WidgetTile","sourcePath":"components/builder/WidgetTile.jsx"},{"name":"Avatar","sourcePath":"components/core/Avatar.jsx"},{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"Tooltip","sourcePath":"components/core/Tooltip.jsx"},{"name":"Checkbox","sourcePath":"components/forms/Checkbox.jsx"},{"name":"Input","sourcePath":"components/forms/Input.jsx"},{"name":"SegmentedControl","sourcePath":"components/forms/SegmentedControl.jsx"},{"name":"Select","sourcePath":"components/forms/Select.jsx"},{"name":"Switch","sourcePath":"components/forms/Switch.jsx"},{"name":"Textarea","sourcePath":"components/forms/Textarea.jsx"},{"name":"Panel","sourcePath":"components/layout/Panel.jsx"},{"name":"Tabs","sourcePath":"components/layout/Tabs.jsx"}],"sourceHashes":{"assets/icons.js":"6415f9dfc164","components/builder/BlockRow.jsx":"256f6a7baa96","components/builder/PropertyRow.jsx":"cd2f8ae71399","components/builder/StageBadge.jsx":"b1ee83627403","components/builder/StateChip.jsx":"ae977507dda2","components/builder/WidgetTile.jsx":"7db94ce2a58a","components/core/Avatar.jsx":"ea560027aae8","components/core/Badge.jsx":"9c3f75d25f20","components/core/Button.jsx":"962705166329","components/core/IconButton.jsx":"4313d06d989f","components/core/Tooltip.jsx":"32b1901909bd","components/forms/Checkbox.jsx":"c0ac93960727","components/forms/Input.jsx":"9e8fceb4ff4c","components/forms/SegmentedControl.jsx":"c6e4fab29334","components/forms/Select.jsx":"b7b12bcb93c1","components/forms/Switch.jsx":"09e947701bd1","components/forms/Textarea.jsx":"63fcba7401ef","components/layout/Panel.jsx":"8aae32834cad","components/layout/Tabs.jsx":"ae771ac17dee","ui_kits/editor/Inspector.jsx":"aca6c8e08f79","ui_kits/editor/Organization.jsx":"8de6b6ae105d","ui_kits/editor/Palette.jsx":"b659fd98e2d9","ui_kits/editor/Preview.jsx":"bf7b5af6e15d","ui_kits/editor/Topbar.jsx":"88fc8532b191","ui_kits/editor/app.jsx":"21c13b3fce37","ui_kits/editor/data.js":"4b5551ee34c7"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.DrivaDesignSystem_5934aa = window.DrivaDesignSystem_5934aa || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// assets/icons.js
try { (() => {
/* ============================================================
   Driva — Icon set
   Curated from Lucide (https://lucide.dev, ISC license): outline,
   24x24, 2px stroke, currentColor. Exposes window.Icon (a React
   component) and window.DRIVA_ICONS (raw inner-SVG strings).
   ============================================================ */
(function () {
  const P = {
    image: '<rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>',
    list: '<line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/>',
    type: '<polyline points="4 7 4 4 20 4 20 7"/><line x1="9" x2="15" y1="20" y2="20"/><line x1="12" x2="12" y1="4" y2="20"/>',
    button: '<rect width="18" height="10" x="3" y="7" rx="3"/><path d="M7 12h.01"/>',
    banner: '<rect width="18" height="7" x="3" y="4" rx="1"/><path d="M5 14h14"/><path d="M5 18h9"/>',
    carousel: '<path d="M2 7v10"/><path d="M6 5v14"/><rect width="12" height="18" x="10" y="3" rx="2"/>',
    card: '<rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/>',
    spacer: '<path d="M5 12h14"/><path d="M9 6 5 12l4 6"/><path d="m15 6 4 6-4 6"/>',
    search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
    plus: '<path d="M5 12h14"/><path d="M12 5v14"/>',
    eye: '<path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/>',
    eyeOff: '<path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49"/><path d="M14.084 14.158a3 3 0 0 1-4.242-4.242"/><path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143"/><path d="m2 2 20 20"/>',
    trash: '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/>',
    sliders: '<line x1="21" x2="14" y1="4" y2="4"/><line x1="10" x2="3" y1="4" y2="4"/><line x1="21" x2="12" y1="12" y2="12"/><line x1="8" x2="3" y1="12" y2="12"/><line x1="21" x2="16" y1="20" y2="20"/><line x1="12" x2="3" y1="20" y2="20"/><line x1="14" x2="14" y1="2" y2="6"/><line x1="8" x2="8" y1="10" y2="14"/><line x1="16" x2="16" y1="18" y2="22"/>',
    smartphone: '<rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><path d="M12 18h.01"/>',
    tablet: '<rect width="16" height="20" x="4" y="2" rx="2" ry="2"/><line x1="12" x2="12.01" y1="18" y2="18"/>',
    monitor: '<rect width="20" height="14" x="2" y="3" rx="2"/><line x1="8" x2="16" y1="21" y2="21"/><line x1="12" x2="12" y1="17" y2="21"/>',
    undo: '<path d="M9 14 4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5 5.5 5.5 0 0 1-5.5 5.5H11"/>',
    redo: '<path d="m15 14 5-5-5-5"/><path d="M20 9H9.5A5.5 5.5 0 0 0 4 14.5 5.5 5.5 0 0 0 9.5 20H13"/>',
    check: '<path d="M20 6 9 17l-5-5"/>',
    chevronDown: '<path d="m6 9 6 6 6-6"/>',
    chevronRight: '<path d="m9 18 6-6-6-6"/>',
    link: '<path d="M9 17H7A5 5 0 0 1 7 7h2"/><path d="M15 7h2a5 5 0 1 1 0 10h-2"/><line x1="8" x2="16" y1="12" y2="12"/>',
    database: '<ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M3 5V19A9 3 0 0 0 21 19V5"/><path d="M3 12A9 3 0 0 0 21 12"/>',
    layers: '<path d="M12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z"/><path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65"/><path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/>',
    panelLeft: '<rect width="18" height="18" x="3" y="3" rx="2"/><path d="M9 3v18"/>',
    play: '<polygon points="6 3 20 12 6 21 6 3"/>',
    zap: '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>',
    save: '<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>',
    clock: '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
    x: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
    more: '<circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/>',
    grid: '<rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/>',
    settings: '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
    bell: '<path d="M10.268 21a2 2 0 0 0 3.464 0"/><path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"/>',
    file: '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/>',
    home: '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
    arrowLeft: '<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>',
    star: '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>',
    cube: '<path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/>',
    copy: '<rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>',
    alert: '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/>'
  };
  function svg(name, size, stroke) {
    return '<svg xmlns="http://www.w3.org/2000/svg" width="' + (size || 24) + '" height="' + (size || 24) + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="' + (stroke || 2) + '" stroke-linecap="round" stroke-linejoin="round">' + (P[name] || '') + '</svg>';
  }
  window.DRIVA_ICONS = P;
  window.drivaIconSvg = svg;
  if (window.React) {
    window.Icon = function Icon(props) {
      var size = props.size || 18;
      var stroke = props.stroke || 2;
      return window.React.createElement('span', {
        className: 'dv-ic',
        style: {
          display: 'inline-flex',
          lineHeight: 0
        },
        'aria-hidden': 'true',
        dangerouslySetInnerHTML: {
          __html: svg(props.name, size, stroke)
        }
      });
    };
  }
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "assets/icons.js", error: String((e && e.message) || e) }); }

// components/builder/BlockRow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * BlockRow — a block placed on the page, shown in the Organization column
 * (center). Selectable, reorderable, removable; mirrors the order of the
 * rendered SDUI page.
 */
function BlockRow({
  name,
  icon = null,
  meta,
  selected = false,
  hidden = false,
  onSelect,
  onRemove,
  dragHandleProps,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-block-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-block-css';
    el.textContent = BLOCK_CSS;
    document.head.appendChild(el);
  }, []);
  return /*#__PURE__*/React.createElement("div", _extends({
    className: `dv-block ${selected ? 'is-selected' : ''} ${hidden ? 'is-hidden' : ''}`,
    onClick: onSelect
  }, rest), /*#__PURE__*/React.createElement("span", _extends({
    className: "dv-block__grip"
  }, dragHandleProps, {
    "aria-label": "Reordenar",
    onClick: e => e.stopPropagation()
  }), /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 16 16",
    fill: "currentColor"
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "6",
    cy: "4",
    r: "1.3"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "10",
    cy: "4",
    r: "1.3"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "6",
    cy: "8",
    r: "1.3"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "10",
    cy: "8",
    r: "1.3"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "6",
    cy: "12",
    r: "1.3"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "10",
    cy: "12",
    r: "1.3"
  }))), /*#__PURE__*/React.createElement("span", {
    className: "dv-block__icon"
  }, icon), /*#__PURE__*/React.createElement("span", {
    className: "dv-block__text"
  }, /*#__PURE__*/React.createElement("span", {
    className: "dv-block__name"
  }, name), meta && /*#__PURE__*/React.createElement("span", {
    className: "dv-block__meta"
  }, meta)), hidden && /*#__PURE__*/React.createElement("span", {
    className: "dv-block__hideflag",
    title: "Oculto no preview"
  }, /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 16 16",
    fill: "none"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M2 8s2.2-4 6-4 6 4 6 4-2.2 4-6 4-6-4-6-4z",
    stroke: "currentColor",
    "stroke-width": "1.3"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M3 3l10 10",
    stroke: "currentColor",
    "stroke-width": "1.3",
    "stroke-linecap": "round"
  }))), onRemove && /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "dv-block__del",
    "aria-label": "Remover bloco",
    onClick: e => {
      e.stopPropagation();
      onRemove();
    }
  }, /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 16 16",
    fill: "none"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M4 4l8 8M12 4l-8 8",
    stroke: "currentColor",
    "stroke-width": "1.4",
    "stroke-linecap": "round"
  }))));
}
const BLOCK_CSS = `
.dv-block{ display:flex; align-items:center; gap:var(--space-5); padding:var(--space-5) var(--space-5);
  background:var(--surface-panel); border:1px solid var(--border-subtle); border-radius:var(--radius-md);
  cursor:pointer; transition:border-color var(--dur-fast) var(--ease-out), background var(--dur-fast) var(--ease-out), box-shadow var(--dur-fast) var(--ease-out); }
.dv-block:hover{ border-color:var(--border-strong); }
.dv-block:hover .dv-block__del{ opacity:1; }
.dv-block.is-selected{ border-color:var(--brand); box-shadow:0 0 0 1px var(--brand), var(--shadow-sm); background:var(--brand-subtle); }
.dv-block.is-hidden{ opacity:.6; }
.dv-block__grip{ display:inline-flex; color:var(--text-subtle); cursor:grab; flex:none; }
.dv-block__grip svg{ width:15px; height:15px; display:block; }
.dv-block__icon{ display:inline-flex; align-items:center; justify-content:center; flex:none;
  width:30px; height:30px; border-radius:var(--radius-sm); background:var(--surface-sunken); color:var(--text-body); }
.dv-block__icon svg{ width:16px; height:16px; }
.dv-block.is-selected .dv-block__icon{ background:#fff; color:var(--brand); }
.dv-block__text{ flex:1; min-width:0; display:flex; flex-direction:column; gap:1px; }
.dv-block__name{ font-family:var(--font-sans); font-weight:var(--fw-semibold); font-size:var(--fs-sm);
  color:var(--text-strong); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.dv-block__meta{ font-family:var(--font-mono); font-size:var(--fs-2xs); color:var(--text-subtle);
  white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.dv-block__hideflag{ display:inline-flex; color:var(--text-subtle); flex:none; }
.dv-block__hideflag svg{ width:15px; height:15px; }
.dv-block__del{ display:inline-flex; align-items:center; justify-content:center; width:24px; height:24px;
  border:none; background:transparent; color:var(--text-subtle); border-radius:var(--radius-sm);
  cursor:pointer; opacity:0; flex:none; transition:opacity var(--dur-fast) var(--ease-out), background var(--dur-fast) var(--ease-out), color var(--dur-fast) var(--ease-out); }
.dv-block__del:hover{ background:var(--danger-subtle); color:var(--danger); }
.dv-block__del svg{ width:14px; height:14px; }
`;
Object.assign(__ds_scope, { BlockRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/builder/BlockRow.jsx", error: String((e && e.message) || e) }); }

// components/builder/PropertyRow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * PropertyRow — a labeled control row in the Inspector. Lays out a property
 * name (with optional binding indicator) beside its editing control.
 */
function PropertyRow({
  label,
  hint,
  bound = false,
  layout = 'stack',
  children,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-prop-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-prop-css';
    el.textContent = PROP_CSS;
    document.head.appendChild(el);
  }, []);
  return /*#__PURE__*/React.createElement("div", _extends({
    className: `dv-prop dv-prop--${layout}`
  }, rest), /*#__PURE__*/React.createElement("div", {
    className: "dv-prop__label"
  }, /*#__PURE__*/React.createElement("span", {
    className: "dv-prop__name"
  }, label), bound && /*#__PURE__*/React.createElement("span", {
    className: "dv-prop__bound",
    title: "Vinculado a um dado"
  }, /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 16 16",
    fill: "none"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M6 10l4-4M7 4.5l.7-.7a2.5 2.5 0 013.5 3.5l-.7.7M9 11.5l-.7.7a2.5 2.5 0 01-3.5-3.5l.7-.7",
    stroke: "currentColor",
    "stroke-width": "1.3",
    "stroke-linecap": "round"
  })))), /*#__PURE__*/React.createElement("div", {
    className: "dv-prop__control"
  }, children), hint && /*#__PURE__*/React.createElement("div", {
    className: "dv-prop__hint"
  }, hint));
}
const PROP_CSS = `
.dv-prop{ display:flex; }
.dv-prop--stack{ flex-direction:column; gap:var(--space-4); padding:var(--space-5) 0; }
.dv-prop--inline{ align-items:center; gap:var(--space-6); padding:var(--space-4) 0; }
.dv-prop--inline .dv-prop__label{ width:104px; flex:none; }
.dv-prop--inline .dv-prop__control{ flex:1; min-width:0; }
.dv-prop--inline .dv-prop__hint{ flex-basis:100%; }
.dv-prop__label{ display:flex; align-items:center; gap:var(--space-3); }
.dv-prop__name{ font-family:var(--font-sans); font-weight:var(--fw-medium); font-size:var(--fs-xs);
  color:var(--text-muted); }
.dv-prop__bound{ display:inline-flex; color:var(--accent); }
.dv-prop__bound svg{ width:13px; height:13px; }
.dv-prop__hint{ font-family:var(--font-sans); font-size:var(--fs-2xs); color:var(--text-subtle);
  line-height:var(--lh-snug); }
`;
Object.assign(__ds_scope, { PropertyRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/builder/PropertyRow.jsx", error: String((e && e.message) || e) }); }

// components/builder/StageBadge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const STAGES = {
  draft: {
    label: 'Rascunho',
    tone: 'draft'
  },
  review: {
    label: 'Homologação',
    tone: 'review'
  },
  prod: {
    label: 'Produção',
    tone: 'prod'
  }
};

/**
 * StageBadge — publish-workflow status for a page or widget
 * (draft → homologation → production). Encodes Driva's governance vocabulary.
 */
function StageBadge({
  stage = 'draft',
  label,
  size = 'md',
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-stage-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-stage-css';
    el.textContent = STAGE_CSS;
    document.head.appendChild(el);
  }, []);
  const cfg = STAGES[stage] || STAGES.draft;
  return /*#__PURE__*/React.createElement("span", _extends({
    className: `dv-stage dv-stage--${cfg.tone} dv-stage--${size}`
  }, rest), /*#__PURE__*/React.createElement("span", {
    className: "dv-stage__dot"
  }), label || cfg.label);
}
const STAGE_CSS = `
.dv-stage{ display:inline-flex; align-items:center; gap:var(--space-4);
  font-family:var(--font-sans); font-weight:var(--fw-semibold); border-radius:var(--radius-pill);
  border:1px solid transparent; white-space:nowrap; }
.dv-stage--md{ font-size:var(--fs-xs); padding:4px var(--space-6); }
.dv-stage--sm{ font-size:var(--fs-2xs); padding:2px var(--space-5); }
.dv-stage__dot{ width:7px; height:7px; border-radius:50%; background:currentColor; flex:none; }
.dv-stage--draft{ color:var(--slate-600); background:var(--stage-draft-bg); border-color:var(--border-default); }
.dv-stage--review{ color:var(--stage-review); background:var(--stage-review-bg); border-color:var(--warning-border); }
.dv-stage--prod{ color:var(--stage-prod); background:var(--stage-prod-bg); border-color:var(--success-border); }
`;
Object.assign(__ds_scope, { StageBadge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/builder/StageBadge.jsx", error: String((e && e.message) || e) }); }

// components/builder/StateChip.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const STATES = {
  idle: {
    label: 'Idle',
    tone: 'idle'
  },
  loading: {
    label: 'Loading',
    tone: 'loading'
  },
  success: {
    label: 'Success',
    tone: 'success'
  },
  error: {
    label: 'Error',
    tone: 'error'
  },
  empty: {
    label: 'Empty',
    tone: 'empty'
  }
};

/**
 * StateChip — selects/labels a widget's component state in the widget builder
 * (idle / loading / success / error / empty). Acts as a toggle when onClick is
 * provided.
 */
function StateChip({
  state = 'idle',
  label,
  active = false,
  onClick,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-statechip-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-statechip-css';
    el.textContent = STATECHIP_CSS;
    document.head.appendChild(el);
  }, []);
  const cfg = STATES[state] || STATES.idle;
  const Tag = onClick ? 'button' : 'span';
  return /*#__PURE__*/React.createElement(Tag, _extends({
    type: onClick ? 'button' : undefined,
    className: `dv-statechip dv-statechip--${cfg.tone} ${active ? 'is-active' : ''} ${onClick ? 'is-btn' : ''}`,
    onClick: onClick
  }, rest), /*#__PURE__*/React.createElement("span", {
    className: "dv-statechip__dot"
  }), label || cfg.label);
}
const STATECHIP_CSS = `
.dv-statechip{ display:inline-flex; align-items:center; gap:var(--space-4);
  font-family:var(--font-sans); font-weight:var(--fw-semibold); font-size:var(--fs-xs);
  padding:4px var(--space-6); border-radius:var(--radius-sm);
  border:1px solid var(--border-subtle); background:var(--surface-panel); color:var(--text-muted); }
.dv-statechip.is-btn{ cursor:pointer; transition:border-color var(--dur-fast) var(--ease-out), background var(--dur-fast) var(--ease-out); }
.dv-statechip__dot{ width:7px; height:7px; border-radius:50%; background:var(--_c, var(--slate-400)); flex:none; }
.dv-statechip--idle{ --_c:var(--state-idle); }
.dv-statechip--loading{ --_c:var(--state-loading); }
.dv-statechip--success{ --_c:var(--state-success); }
.dv-statechip--error{ --_c:var(--state-error); }
.dv-statechip--empty{ --_c:var(--state-empty); }
.dv-statechip.is-btn:hover{ border-color:var(--border-strong); }
.dv-statechip.is-active{ color:var(--text-strong); border-color:var(--_c); background:color-mix(in srgb, var(--_c) 9%, #fff); box-shadow:0 0 0 1px var(--_c); }
`;
Object.assign(__ds_scope, { StateChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/builder/StateChip.jsx", error: String((e && e.message) || e) }); }

// components/builder/WidgetTile.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * WidgetTile — a draggable item in the palette (left column). Represents a
 * widget the user can drag onto the page canvas.
 */
function WidgetTile({
  name,
  icon = null,
  category,
  layout = 'grid',
  draggable = true,
  onClick,
  onDragStart,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-wtile-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-wtile-css';
    el.textContent = WTILE_CSS;
    document.head.appendChild(el);
  }, []);
  return /*#__PURE__*/React.createElement("div", _extends({
    className: `dv-wtile dv-wtile--${layout}`,
    draggable: draggable,
    onClick: onClick,
    onDragStart: onDragStart,
    role: "button",
    tabIndex: 0
  }, rest), /*#__PURE__*/React.createElement("span", {
    className: "dv-wtile__grip",
    "aria-hidden": "true"
  }, /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 16 16",
    fill: "currentColor"
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "5",
    cy: "4",
    r: "1.3"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "11",
    cy: "4",
    r: "1.3"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "5",
    cy: "8",
    r: "1.3"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "11",
    cy: "8",
    r: "1.3"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "5",
    cy: "12",
    r: "1.3"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "11",
    cy: "12",
    r: "1.3"
  }))), /*#__PURE__*/React.createElement("span", {
    className: "dv-wtile__icon"
  }, icon), /*#__PURE__*/React.createElement("span", {
    className: "dv-wtile__name"
  }, name), category && /*#__PURE__*/React.createElement("span", {
    className: "dv-wtile__cat"
  }, category));
}
const WTILE_CSS = `
.dv-wtile{ position:relative; display:flex; align-items:center; background:var(--surface-panel);
  border:1px solid var(--border-subtle); border-radius:var(--radius-md); cursor:grab;
  transition:border-color var(--dur-fast) var(--ease-out), box-shadow var(--dur-fast) var(--ease-out), transform var(--dur-fast) var(--ease-out); }
.dv-wtile:hover{ border-color:var(--brand-border); box-shadow:var(--shadow-sm); }
.dv-wtile:active{ cursor:grabbing; }
.dv-wtile:focus-visible{ outline:none; box-shadow:var(--ring); }

/* grid layout — palette card */
.dv-wtile--grid{ flex-direction:column; align-items:flex-start; gap:var(--space-5);
  padding:var(--space-7) var(--space-6); }
.dv-wtile--grid .dv-wtile__grip{ display:none; }
.dv-wtile--grid .dv-wtile__icon{ display:inline-flex; align-items:center; justify-content:center;
  width:32px; height:32px; border-radius:var(--radius-sm); background:var(--brand-subtle); color:var(--brand); }
.dv-wtile--grid .dv-wtile__icon svg{ width:18px; height:18px; }
.dv-wtile--grid .dv-wtile__name{ font-family:var(--font-sans); font-weight:var(--fw-semibold);
  font-size:var(--fs-sm); color:var(--text-strong); }
.dv-wtile--grid .dv-wtile__cat{ display:none; }

/* list layout — search results / compact palette */
.dv-wtile--list{ gap:var(--space-5); padding:var(--space-4) var(--space-5); }
.dv-wtile--list .dv-wtile__grip{ display:inline-flex; color:var(--text-subtle); }
.dv-wtile--list .dv-wtile__grip svg{ width:14px; height:14px; }
.dv-wtile--list .dv-wtile__icon{ display:inline-flex; align-items:center; justify-content:center;
  width:26px; height:26px; border-radius:var(--radius-sm); background:var(--brand-subtle); color:var(--brand); flex:none; }
.dv-wtile--list .dv-wtile__icon svg{ width:15px; height:15px; }
.dv-wtile--list .dv-wtile__name{ flex:1; font-family:var(--font-sans); font-weight:var(--fw-medium);
  font-size:var(--fs-sm); color:var(--text-strong); }
.dv-wtile--list .dv-wtile__cat{ font-family:var(--font-sans); font-size:var(--fs-2xs); color:var(--text-subtle);
  text-transform:uppercase; letter-spacing:var(--ls-wider); }
`;
Object.assign(__ds_scope, { WidgetTile });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/builder/WidgetTile.jsx", error: String((e && e.message) || e) }); }

// components/core/Avatar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * User avatar with initials fallback. Used in topbar, workflow assignees,
 * comment threads.
 */
function Avatar({
  name = '',
  src = null,
  size = 'md',
  tone = 'auto',
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-avatar-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-avatar-css';
    el.textContent = AVATAR_CSS;
    document.head.appendChild(el);
  }, []);
  const initials = name.split(/\s+/).filter(Boolean).slice(0, 2).map(w => w[0]).join('').toUpperCase() || '?';
  const tones = ['a', 'b', 'c', 'd', 'e'];
  const auto = tones[(name.charCodeAt(0) || 0) % tones.length];
  const t = tone === 'auto' ? auto : tone;
  return /*#__PURE__*/React.createElement("span", _extends({
    className: `dv-avatar dv-avatar--${size} dv-avatar--t-${t}`,
    title: name
  }, rest), src ? /*#__PURE__*/React.createElement("img", {
    className: "dv-avatar__img",
    src: src,
    alt: name
  }) : /*#__PURE__*/React.createElement("span", {
    className: "dv-avatar__initials"
  }, initials));
}
const AVATAR_CSS = `
.dv-avatar{ display:inline-flex; align-items:center; justify-content:center;
  border-radius:50%; overflow:hidden; font-family:var(--font-sans); font-weight:var(--fw-semibold);
  background:var(--slate-200); color:var(--slate-700); flex:none; user-select:none;
  box-shadow:inset 0 0 0 1px rgba(13,18,28,.06); }
.dv-avatar--xs{ width:20px; height:20px; font-size:9px; }
.dv-avatar--sm{ width:26px; height:26px; font-size:11px; }
.dv-avatar--md{ width:32px; height:32px; font-size:12px; }
.dv-avatar--lg{ width:40px; height:40px; font-size:15px; }
.dv-avatar__img{ width:100%; height:100%; object-fit:cover; }
.dv-avatar--t-a{ background:var(--blue-100); color:var(--blue-700); }
.dv-avatar--t-b{ background:var(--violet-100); color:var(--violet-700); }
.dv-avatar--t-c{ background:var(--green-100); color:var(--green-700); }
.dv-avatar--t-d{ background:var(--amber-100); color:var(--amber-700); }
.dv-avatar--t-e{ background:var(--sky-100); color:var(--sky-600); }
`;
Object.assign(__ds_scope, { Avatar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Avatar.jsx", error: String((e && e.message) || e) }); }

// components/core/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Compact status / category label. Use `tone` for semantic meaning and
 * `variant` for solid vs. soft fill.
 */
function Badge({
  children,
  tone = 'neutral',
  variant = 'soft',
  dot = false,
  iconLeft = null,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-badge-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-badge-css';
    el.textContent = BADGE_CSS;
    document.head.appendChild(el);
  }, []);
  const cls = ['dv-badge', `dv-badge--${variant}`, `dv-badge--${tone}`].join(' ');
  return /*#__PURE__*/React.createElement("span", _extends({
    className: cls
  }, rest), dot && /*#__PURE__*/React.createElement("span", {
    className: "dv-badge__dot"
  }), iconLeft && /*#__PURE__*/React.createElement("span", {
    className: "dv-badge__icon"
  }, iconLeft), children);
}
const BADGE_CSS = `
.dv-badge{
  --_fg:var(--slate-600); --_bg:var(--slate-100); --_bd:transparent;
  display:inline-flex; align-items:center; gap:var(--space-3);
  font-family:var(--font-sans); font-weight:var(--fw-semibold);
  font-size:var(--fs-2xs); line-height:1; letter-spacing:.01em;
  padding:3px var(--space-5); border-radius:var(--radius-pill);
  border:1px solid var(--_bd); background:var(--_bg); color:var(--_fg); white-space:nowrap;
}
.dv-badge__dot{ width:6px; height:6px; border-radius:50%; background:currentColor; }
.dv-badge__icon{ display:inline-flex; }
.dv-badge__icon svg{ width:12px; height:12px; display:block; }

.dv-badge--soft.dv-badge--neutral{ --_bg:var(--slate-100); --_fg:var(--slate-600); }
.dv-badge--soft.dv-badge--brand{ --_bg:var(--brand-subtle); --_fg:var(--blue-700); }
.dv-badge--soft.dv-badge--success{ --_bg:var(--success-subtle); --_fg:var(--green-700); }
.dv-badge--soft.dv-badge--warning{ --_bg:var(--warning-subtle); --_fg:var(--amber-700); }
.dv-badge--soft.dv-badge--danger{ --_bg:var(--danger-subtle); --_fg:var(--red-700); }
.dv-badge--soft.dv-badge--info{ --_bg:var(--info-subtle); --_fg:var(--sky-600); }
.dv-badge--soft.dv-badge--accent{ --_bg:var(--accent-subtle); --_fg:var(--violet-700); }

.dv-badge--solid{ --_fg:#fff; }
.dv-badge--solid.dv-badge--neutral{ --_bg:var(--slate-600); }
.dv-badge--solid.dv-badge--brand{ --_bg:var(--brand); }
.dv-badge--solid.dv-badge--success{ --_bg:var(--success); }
.dv-badge--solid.dv-badge--warning{ --_bg:var(--amber-600); }
.dv-badge--solid.dv-badge--danger{ --_bg:var(--danger); }
.dv-badge--solid.dv-badge--info{ --_bg:var(--info); }
.dv-badge--solid.dv-badge--accent{ --_bg:var(--accent); }

.dv-badge--outline{ --_bg:transparent; --_bd:var(--border-default); --_fg:var(--text-muted); }
`;
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Driva Button — the primary action primitive across the editor chrome,
 * dialogs, and forms.
 */
function Button({
  children,
  variant = 'primary',
  size = 'md',
  iconLeft = null,
  iconRight = null,
  block = false,
  disabled = false,
  loading = false,
  type = 'button',
  onClick,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-button-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-button-css';
    el.textContent = BUTTON_CSS;
    document.head.appendChild(el);
  }, []);
  const cls = ['dv-btn', `dv-btn--${variant}`, `dv-btn--${size}`, block ? 'dv-btn--block' : '', loading ? 'dv-btn--loading' : ''].filter(Boolean).join(' ');
  return /*#__PURE__*/React.createElement("button", _extends({
    type: type,
    className: cls,
    disabled: disabled || loading,
    onClick: onClick
  }, rest), loading && /*#__PURE__*/React.createElement("span", {
    className: "dv-btn__spin",
    "aria-hidden": "true"
  }), !loading && iconLeft && /*#__PURE__*/React.createElement("span", {
    className: "dv-btn__icon"
  }, iconLeft), children && /*#__PURE__*/React.createElement("span", {
    className: "dv-btn__label"
  }, children), !loading && iconRight && /*#__PURE__*/React.createElement("span", {
    className: "dv-btn__icon"
  }, iconRight));
}
const BUTTON_CSS = `
.dv-btn{
  --_bg:var(--brand); --_fg:var(--brand-contrast); --_bd:transparent;
  display:inline-flex; align-items:center; justify-content:center; gap:var(--space-3);
  font-family:var(--font-sans); font-weight:var(--fw-semibold); white-space:nowrap;
  border:1px solid var(--_bd); background:var(--_bg); color:var(--_fg);
  border-radius:var(--radius-md); cursor:pointer; user-select:none;
  transition:background var(--dur-fast) var(--ease-out), box-shadow var(--dur-fast) var(--ease-out),
             border-color var(--dur-fast) var(--ease-out), transform var(--dur-fast) var(--ease-out);
}
.dv-btn:focus-visible{ outline:none; box-shadow:var(--ring); }
.dv-btn:active:not(:disabled){ transform:translateY(0.5px); }
.dv-btn:disabled{ opacity:.5; cursor:not-allowed; }
.dv-btn__icon{ display:inline-flex; }
.dv-btn__icon svg{ width:1.05em; height:1.05em; display:block; }

/* sizes */
.dv-btn--sm{ height:28px; padding:0 var(--space-6); font-size:var(--fs-sm); border-radius:var(--radius-sm); }
.dv-btn--md{ height:36px; padding:0 var(--space-8); font-size:var(--fs-body); }
.dv-btn--lg{ height:44px; padding:0 var(--space-12); font-size:var(--fs-body-lg); border-radius:var(--radius-lg); }
.dv-btn--block{ width:100%; }

/* primary */
.dv-btn--primary{ --_bg:var(--brand); --_fg:var(--brand-contrast); box-shadow:var(--shadow-sm); }
.dv-btn--primary:hover:not(:disabled){ --_bg:var(--brand-hover); }
.dv-btn--primary:active:not(:disabled){ --_bg:var(--brand-active); }

/* secondary (neutral outline on white) */
.dv-btn--secondary{ --_bg:var(--surface-panel); --_fg:var(--text-body); --_bd:var(--border-default); box-shadow:var(--shadow-xs); }
.dv-btn--secondary:hover:not(:disabled){ --_bg:var(--surface-hover); --_bd:var(--border-strong); }
.dv-btn--secondary:active:not(:disabled){ --_bg:var(--surface-active); }

/* ghost */
.dv-btn--ghost{ --_bg:transparent; --_fg:var(--text-body); }
.dv-btn--ghost:hover:not(:disabled){ --_bg:var(--surface-hover); }
.dv-btn--ghost:active:not(:disabled){ --_bg:var(--surface-active); }

/* danger */
.dv-btn--danger{ --_bg:var(--danger); --_fg:#fff; box-shadow:var(--shadow-sm); }
.dv-btn--danger:hover:not(:disabled){ --_bg:var(--danger-hover); }

/* subtle (brand tint) */
.dv-btn--subtle{ --_bg:var(--brand-subtle); --_fg:var(--brand-hover); }
.dv-btn--subtle:hover:not(:disabled){ --_bg:var(--brand-subtle-2); }

/* loading spinner */
.dv-btn__spin{ width:1em; height:1em; border-radius:50%;
  border:2px solid color-mix(in srgb, currentColor 30%, transparent);
  border-top-color:currentColor; animation:dv-btn-spin .6s linear infinite; }
@keyframes dv-btn-spin{ to{ transform:rotate(360deg); } }
`;
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Square icon-only button — toolbars, panel headers, block controls.
 */
function IconButton({
  children,
  label,
  variant = 'ghost',
  size = 'md',
  active = false,
  disabled = false,
  onClick,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-iconbtn-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-iconbtn-css';
    el.textContent = ICONBTN_CSS;
    document.head.appendChild(el);
  }, []);
  const cls = ['dv-iconbtn', `dv-iconbtn--${variant}`, `dv-iconbtn--${size}`, active ? 'is-active' : ''].filter(Boolean).join(' ');
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    className: cls,
    "aria-label": label,
    title: label,
    "aria-pressed": active || undefined,
    disabled: disabled,
    onClick: onClick
  }, rest), children);
}
const ICONBTN_CSS = `
.dv-iconbtn{
  --_bg:transparent; --_fg:var(--text-muted); --_bd:transparent;
  display:inline-flex; align-items:center; justify-content:center;
  background:var(--_bg); color:var(--_fg); border:1px solid var(--_bd);
  border-radius:var(--radius-sm); cursor:pointer;
  transition:background var(--dur-fast) var(--ease-out), color var(--dur-fast) var(--ease-out),
             border-color var(--dur-fast) var(--ease-out);
}
.dv-iconbtn svg{ width:1.15em; height:1.15em; display:block; }
.dv-iconbtn--sm{ width:28px; height:28px; font-size:14px; }
.dv-iconbtn--md{ width:32px; height:32px; font-size:16px; }
.dv-iconbtn--lg{ width:40px; height:40px; font-size:18px; }
.dv-iconbtn:focus-visible{ outline:none; box-shadow:var(--ring); }
.dv-iconbtn:disabled{ opacity:.4; cursor:not-allowed; }

.dv-iconbtn--ghost:hover:not(:disabled){ --_bg:var(--surface-hover); --_fg:var(--text-body); }
.dv-iconbtn--ghost.is-active{ --_bg:var(--brand-subtle); --_fg:var(--brand); }

.dv-iconbtn--outline{ --_bd:var(--border-default); --_fg:var(--text-body); --_bg:var(--surface-panel); }
.dv-iconbtn--outline:hover:not(:disabled){ --_bg:var(--surface-hover); --_bd:var(--border-strong); }
.dv-iconbtn--outline.is-active{ --_bg:var(--brand-subtle); --_fg:var(--brand); --_bd:var(--brand-border); }
`;
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/core/Tooltip.jsx
try { (() => {
/**
 * Lightweight CSS tooltip wrapper. Wraps a single trigger child and shows
 * `label` on hover/focus. For editor chrome only (not the Flutter preview).
 */
function Tooltip({
  label,
  side = 'top',
  children
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-tooltip-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-tooltip-css';
    el.textContent = TOOLTIP_CSS;
    document.head.appendChild(el);
  }, []);
  return /*#__PURE__*/React.createElement("span", {
    className: `dv-tip dv-tip--${side}`,
    "data-tip": label,
    tabIndex: -1
  }, children);
}
const TOOLTIP_CSS = `
.dv-tip{ position:relative; display:inline-flex; }
.dv-tip::after{
  content:attr(data-tip); position:absolute; z-index:60;
  background:var(--surface-inverse); color:#fff; font-family:var(--font-sans);
  font-size:var(--fs-xs); font-weight:var(--fw-medium); line-height:1.3;
  padding:5px var(--space-5); border-radius:var(--radius-sm); white-space:nowrap;
  box-shadow:var(--shadow-lg); opacity:0; pointer-events:none;
  transform:translateY(2px); transition:opacity var(--dur-fast) var(--ease-out), transform var(--dur-fast) var(--ease-out);
}
.dv-tip:hover::after, .dv-tip:focus-within::after{ opacity:1; transform:translateY(0); }
.dv-tip--top::after{ bottom:100%; left:50%; transform:translate(-50%,2px); margin-bottom:7px; }
.dv-tip--top:hover::after{ transform:translate(-50%,0); }
.dv-tip--bottom::after{ top:100%; left:50%; transform:translate(-50%,-2px); margin-top:7px; }
.dv-tip--bottom:hover::after{ transform:translate(-50%,0); }
.dv-tip--right::after{ left:100%; top:50%; transform:translate(-2px,-50%); margin-left:7px; }
.dv-tip--right:hover::after{ transform:translate(0,-50%); }
.dv-tip--left::after{ right:100%; top:50%; transform:translate(2px,-50%); margin-right:7px; }
.dv-tip--left:hover::after{ transform:translate(0,-50%); }
`;
Object.assign(__ds_scope, { Tooltip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Tooltip.jsx", error: String((e && e.message) || e) }); }

// components/forms/Checkbox.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Checkbox with optional label. For multi-select lists and settings.
 */
function Checkbox({
  checked = false,
  indeterminate = false,
  onChange,
  label,
  disabled = false,
  ...rest
}) {
  const ref = React.useRef(null);
  React.useEffect(() => {
    if (document.getElementById('dv-check-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-check-css';
    el.textContent = CHECK_CSS;
    document.head.appendChild(el);
  }, []);
  React.useEffect(() => {
    if (ref.current) ref.current.indeterminate = indeterminate;
  }, [indeterminate]);
  return /*#__PURE__*/React.createElement("label", {
    className: `dv-check ${disabled ? 'is-disabled' : ''}`
  }, /*#__PURE__*/React.createElement("span", {
    className: "dv-check__box"
  }, /*#__PURE__*/React.createElement("input", _extends({
    ref: ref,
    type: "checkbox",
    checked: checked,
    disabled: disabled,
    onChange: e => onChange && onChange(e.target.checked)
  }, rest)), /*#__PURE__*/React.createElement("svg", {
    className: "dv-check__mark",
    viewBox: "0 0 16 16",
    fill: "none",
    "aria-hidden": "true"
  }, indeterminate ? /*#__PURE__*/React.createElement("path", {
    d: "M4 8h8",
    stroke: "#fff",
    "stroke-width": "2",
    "stroke-linecap": "round"
  }) : /*#__PURE__*/React.createElement("path", {
    d: "M3.5 8.5l3 3 6-6.5",
    stroke: "#fff",
    "stroke-width": "2",
    "stroke-linecap": "round",
    "stroke-linejoin": "round"
  }))), label && /*#__PURE__*/React.createElement("span", {
    className: "dv-check__label"
  }, label));
}
const CHECK_CSS = `
.dv-check{ display:inline-flex; align-items:center; gap:var(--space-5); cursor:pointer; user-select:none; }
.dv-check.is-disabled{ opacity:.5; cursor:not-allowed; }
.dv-check__box{ position:relative; width:18px; height:18px; flex:none; }
.dv-check__box input{ position:absolute; inset:0; opacity:0; margin:0; cursor:inherit; }
.dv-check__box::before{ content:""; position:absolute; inset:0; border-radius:var(--radius-xs);
  border:1.5px solid var(--border-strong); background:var(--surface-panel);
  transition:background var(--dur-fast) var(--ease-out), border-color var(--dur-fast) var(--ease-out); }
.dv-check__mark{ position:absolute; inset:0; width:18px; height:18px; opacity:0;
  transition:opacity var(--dur-fast) var(--ease-out); }
.dv-check__box:has(input:checked)::before, .dv-check__box:has(input:indeterminate)::before{
  background:var(--brand); border-color:var(--brand); }
.dv-check__box:has(input:checked) .dv-check__mark, .dv-check__box:has(input:indeterminate) .dv-check__mark{ opacity:1; }
.dv-check__box:has(input:focus-visible)::before{ box-shadow:var(--ring); }
.dv-check__label{ font-family:var(--font-sans); font-size:var(--fs-body); color:var(--text-body); }
`;
Object.assign(__ds_scope, { Checkbox });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Checkbox.jsx", error: String((e && e.message) || e) }); }

// components/forms/Input.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Text input / field. The Inspector's primary control for string and
 * number properties.
 */
function Input({
  value,
  onChange,
  placeholder,
  type = 'text',
  size = 'md',
  prefix = null,
  suffix = null,
  invalid = false,
  disabled = false,
  mono = false,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-input-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-input-css';
    el.textContent = INPUT_CSS;
    document.head.appendChild(el);
  }, []);
  const cls = ['dv-field', `dv-field--${size}`, invalid ? 'is-invalid' : '', disabled ? 'is-disabled' : ''].filter(Boolean).join(' ');
  return /*#__PURE__*/React.createElement("div", {
    className: cls
  }, prefix && /*#__PURE__*/React.createElement("span", {
    className: "dv-field__affix"
  }, prefix), /*#__PURE__*/React.createElement("input", _extends({
    className: "dv-field__input",
    style: mono ? {
      fontFamily: 'var(--font-mono)'
    } : undefined,
    type: type,
    value: value,
    onChange: onChange,
    placeholder: placeholder,
    disabled: disabled
  }, rest)), suffix && /*#__PURE__*/React.createElement("span", {
    className: "dv-field__affix dv-field__affix--end"
  }, suffix));
}
const INPUT_CSS = `
.dv-field{
  display:flex; align-items:center; gap:var(--space-3);
  background:var(--surface-panel); border:1px solid var(--border-default);
  border-radius:var(--radius-md); padding:0 var(--space-5); width:100%;
  transition:border-color var(--dur-fast) var(--ease-out), box-shadow var(--dur-fast) var(--ease-out);
}
.dv-field--sm{ height:28px; }
.dv-field--md{ height:34px; }
.dv-field--lg{ height:40px; }
.dv-field:hover:not(.is-disabled){ border-color:var(--border-strong); }
.dv-field:focus-within{ border-color:var(--border-focus); box-shadow:var(--ring); }
.dv-field.is-invalid{ border-color:var(--danger); }
.dv-field.is-invalid:focus-within{ box-shadow:0 0 0 3px color-mix(in srgb, var(--danger) 24%, transparent); }
.dv-field.is-disabled{ background:var(--slate-50); cursor:not-allowed; }
.dv-field__input{
  flex:1; min-width:0; border:none; outline:none; background:transparent;
  font-family:var(--font-sans); font-size:var(--fs-body); color:var(--text-strong);
  height:100%; padding:0;
}
.dv-field__input::placeholder{ color:var(--text-subtle); }
.dv-field__input:disabled{ cursor:not-allowed; color:var(--text-disabled); }
.dv-field__affix{ display:inline-flex; align-items:center; color:var(--text-subtle);
  font-family:var(--font-mono); font-size:var(--fs-sm); flex:none; }
.dv-field__affix svg{ width:15px; height:15px; display:block; }
`;
Object.assign(__ds_scope, { Input });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Input.jsx", error: String((e && e.message) || e) }); }

// components/forms/SegmentedControl.jsx
try { (() => {
/**
 * Segmented control — a compact set of mutually-exclusive options. Heavily
 * used in Driva for device selection, alignment, and view toggles.
 */
function SegmentedControl({
  value,
  onChange,
  options = [],
  size = 'md',
  fill = false
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-seg-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-seg-css';
    el.textContent = SEG_CSS;
    document.head.appendChild(el);
  }, []);
  return /*#__PURE__*/React.createElement("div", {
    className: `dv-seg dv-seg--${size} ${fill ? 'dv-seg--fill' : ''}`,
    role: "tablist"
  }, options.map(o => {
    const opt = typeof o === 'string' ? {
      value: o,
      label: o
    } : o;
    const on = opt.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: opt.value,
      type: "button",
      role: "tab",
      "aria-selected": on,
      className: `dv-seg__item ${on ? 'is-on' : ''}`,
      title: opt.title || opt.label,
      onClick: () => onChange && onChange(opt.value)
    }, opt.icon && /*#__PURE__*/React.createElement("span", {
      className: "dv-seg__icon"
    }, opt.icon), opt.label && /*#__PURE__*/React.createElement("span", null, opt.label));
  }));
}
const SEG_CSS = `
.dv-seg{ display:inline-flex; background:var(--surface-sunken); border:1px solid var(--border-subtle);
  border-radius:var(--radius-md); padding:2px; gap:2px; }
.dv-seg--fill{ display:flex; width:100%; }
.dv-seg--fill .dv-seg__item{ flex:1; }
.dv-seg__item{ display:inline-flex; align-items:center; justify-content:center; gap:var(--space-3);
  border:none; background:transparent; color:var(--text-muted); cursor:pointer;
  font-family:var(--font-sans); font-weight:var(--fw-medium); border-radius:var(--radius-sm);
  transition:background var(--dur-fast) var(--ease-out), color var(--dur-fast) var(--ease-out), box-shadow var(--dur-fast) var(--ease-out); }
.dv-seg--sm .dv-seg__item{ height:24px; padding:0 var(--space-5); font-size:var(--fs-xs); }
.dv-seg--md .dv-seg__item{ height:30px; padding:0 var(--space-7); font-size:var(--fs-sm); }
.dv-seg__icon{ display:inline-flex; }
.dv-seg__icon svg{ width:15px; height:15px; display:block; }
.dv-seg__item:hover:not(.is-on){ color:var(--text-body); }
.dv-seg__item.is-on{ background:var(--surface-panel); color:var(--text-strong); box-shadow:var(--shadow-sm); }
.dv-seg__item:focus-visible{ outline:none; box-shadow:var(--ring); }
`;
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/forms/Select.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Native select styled to match Driva fields. For enum properties in the
 * Inspector (alignment, fit, device, etc.).
 */
function Select({
  value,
  onChange,
  options = [],
  size = 'md',
  placeholder,
  disabled = false,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-select-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-select-css';
    el.textContent = SELECT_CSS;
    document.head.appendChild(el);
  }, []);
  return /*#__PURE__*/React.createElement("div", {
    className: `dv-select dv-select--${size} ${disabled ? 'is-disabled' : ''}`
  }, /*#__PURE__*/React.createElement("select", _extends({
    className: "dv-select__el",
    value: value,
    onChange: onChange,
    disabled: disabled
  }, rest), placeholder && /*#__PURE__*/React.createElement("option", {
    value: "",
    disabled: true
  }, placeholder), options.map(o => {
    const opt = typeof o === 'string' ? {
      value: o,
      label: o
    } : o;
    return /*#__PURE__*/React.createElement("option", {
      key: opt.value,
      value: opt.value
    }, opt.label);
  })), /*#__PURE__*/React.createElement("span", {
    className: "dv-select__chev",
    "aria-hidden": "true"
  }, /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 16 16",
    fill: "none"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M4 6l4 4 4-4",
    stroke: "currentColor",
    "stroke-width": "1.5",
    "stroke-linecap": "round",
    "stroke-linejoin": "round"
  }))));
}
const SELECT_CSS = `
.dv-select{ position:relative; width:100%; }
.dv-select__el{
  appearance:none; -webkit-appearance:none; width:100%;
  background:var(--surface-panel); border:1px solid var(--border-default);
  border-radius:var(--radius-md); color:var(--text-strong);
  font-family:var(--font-sans); font-size:var(--fs-body);
  padding:0 var(--space-10) 0 var(--space-5); cursor:pointer;
  transition:border-color var(--dur-fast) var(--ease-out), box-shadow var(--dur-fast) var(--ease-out);
}
.dv-select--sm .dv-select__el{ height:28px; }
.dv-select--md .dv-select__el{ height:34px; }
.dv-select--lg .dv-select__el{ height:40px; }
.dv-select__el:hover{ border-color:var(--border-strong); }
.dv-select__el:focus{ outline:none; border-color:var(--border-focus); box-shadow:var(--ring); }
.dv-select.is-disabled .dv-select__el{ background:var(--slate-50); color:var(--text-disabled); cursor:not-allowed; }
.dv-select__chev{ position:absolute; right:var(--space-4); top:50%; transform:translateY(-50%);
  pointer-events:none; color:var(--text-subtle); display:inline-flex; }
.dv-select__chev svg{ width:16px; height:16px; }
`;
Object.assign(__ds_scope, { Select });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Select.jsx", error: String((e && e.message) || e) }); }

// components/forms/Switch.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * On/off switch for boolean properties (e.g. "Exibir bloco", "Largura total").
 */
function Switch({
  checked = false,
  onChange,
  size = 'md',
  label,
  disabled = false,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-switch-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-switch-css';
    el.textContent = SWITCH_CSS;
    document.head.appendChild(el);
  }, []);
  const toggle = () => {
    if (!disabled && onChange) onChange(!checked);
  };
  const sw = /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    role: "switch",
    "aria-checked": checked,
    disabled: disabled,
    className: `dv-switch dv-switch--${size} ${checked ? 'is-on' : ''}`,
    onClick: toggle
  }, rest), /*#__PURE__*/React.createElement("span", {
    className: "dv-switch__thumb"
  }));
  if (!label) return sw;
  return /*#__PURE__*/React.createElement("label", {
    className: "dv-switch-row"
  }, sw, /*#__PURE__*/React.createElement("span", {
    className: "dv-switch-row__label"
  }, label));
}
const SWITCH_CSS = `
.dv-switch{ position:relative; display:inline-flex; align-items:center; flex:none;
  background:var(--slate-300); border:none; border-radius:var(--radius-pill); cursor:pointer; padding:0;
  transition:background var(--dur-base) var(--ease-out); }
.dv-switch--sm{ width:30px; height:18px; }
.dv-switch--md{ width:38px; height:22px; }
.dv-switch__thumb{ position:absolute; top:2px; left:2px; background:#fff; border-radius:50%;
  box-shadow:var(--shadow-sm); transition:transform var(--dur-base) var(--ease-spring); }
.dv-switch--sm .dv-switch__thumb{ width:14px; height:14px; }
.dv-switch--md .dv-switch__thumb{ width:18px; height:18px; }
.dv-switch.is-on{ background:var(--brand); }
.dv-switch--sm.is-on .dv-switch__thumb{ transform:translateX(12px); }
.dv-switch--md.is-on .dv-switch__thumb{ transform:translateX(16px); }
.dv-switch:focus-visible{ outline:none; box-shadow:var(--ring); }
.dv-switch:disabled{ opacity:.5; cursor:not-allowed; }
.dv-switch-row{ display:inline-flex; align-items:center; gap:var(--space-5); cursor:pointer; }
.dv-switch-row__label{ font-family:var(--font-sans); font-size:var(--fs-body); color:var(--text-body); }
`;
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Switch.jsx", error: String((e && e.message) || e) }); }

// components/forms/Textarea.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Multi-line text area for longer property values (descriptions, raw
 * JSON snippets, binding expressions).
 */
function Textarea({
  value,
  onChange,
  placeholder,
  rows = 3,
  mono = false,
  invalid = false,
  disabled = false,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-textarea-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-textarea-css';
    el.textContent = TEXTAREA_CSS;
    document.head.appendChild(el);
  }, []);
  const cls = ['dv-textarea', invalid ? 'is-invalid' : '', mono ? 'dv-textarea--mono' : ''].filter(Boolean).join(' ');
  return /*#__PURE__*/React.createElement("textarea", _extends({
    className: cls,
    value: value,
    onChange: onChange,
    placeholder: placeholder,
    rows: rows,
    disabled: disabled
  }, rest));
}
const TEXTAREA_CSS = `
.dv-textarea{
  width:100%; resize:vertical; background:var(--surface-panel);
  border:1px solid var(--border-default); border-radius:var(--radius-md);
  padding:var(--space-5) var(--space-5); font-family:var(--font-sans);
  font-size:var(--fs-body); line-height:var(--lh-normal); color:var(--text-strong);
  transition:border-color var(--dur-fast) var(--ease-out), box-shadow var(--dur-fast) var(--ease-out);
}
.dv-textarea--mono{ font-family:var(--font-mono); font-size:var(--fs-sm); }
.dv-textarea::placeholder{ color:var(--text-subtle); }
.dv-textarea:hover:not(:disabled){ border-color:var(--border-strong); }
.dv-textarea:focus{ outline:none; border-color:var(--border-focus); box-shadow:var(--ring); }
.dv-textarea.is-invalid{ border-color:var(--danger); }
.dv-textarea:disabled{ background:var(--slate-50); cursor:not-allowed; color:var(--text-disabled); }
`;
Object.assign(__ds_scope, { Textarea });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Textarea.jsx", error: String((e && e.message) || e) }); }

// components/layout/Panel.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Panel — a titled surface region. The editor's structural building block:
 * palette column, inspector column, settings cards.
 */
function Panel({
  title,
  icon = null,
  actions = null,
  children,
  padded = true,
  scroll = false,
  ...rest
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-panel-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-panel-css';
    el.textContent = PANEL_CSS;
    document.head.appendChild(el);
  }, []);
  return /*#__PURE__*/React.createElement("section", _extends({
    className: "dv-panel"
  }, rest), (title || actions) && /*#__PURE__*/React.createElement("header", {
    className: "dv-panel__head"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-panel__title"
  }, icon && /*#__PURE__*/React.createElement("span", {
    className: "dv-panel__icon"
  }, icon), title), actions && /*#__PURE__*/React.createElement("div", {
    className: "dv-panel__actions"
  }, actions)), /*#__PURE__*/React.createElement("div", {
    className: `dv-panel__body ${padded ? 'is-padded' : ''} ${scroll ? 'is-scroll' : ''}`
  }, children));
}
const PANEL_CSS = `
.dv-panel{ display:flex; flex-direction:column; min-height:0; background:var(--surface-panel);
  border:1px solid var(--border-subtle); border-radius:var(--radius-lg); overflow:hidden; }
.dv-panel__head{ display:flex; align-items:center; justify-content:space-between; gap:var(--space-4);
  height:var(--toolbar-h); padding:0 var(--space-6) 0 var(--space-8);
  border-bottom:1px solid var(--border-subtle); flex:none; }
.dv-panel__title{ display:flex; align-items:center; gap:var(--space-5);
  font-family:var(--font-sans); font-weight:var(--fw-semibold); font-size:var(--fs-sm);
  color:var(--text-strong); letter-spacing:var(--ls-tight); }
.dv-panel__icon{ display:inline-flex; color:var(--text-muted); }
.dv-panel__icon svg{ width:16px; height:16px; display:block; }
.dv-panel__actions{ display:flex; align-items:center; gap:var(--space-2); }
.dv-panel__body{ min-height:0; }
.dv-panel__body.is-padded{ padding:var(--space-8); }
.dv-panel__body.is-scroll{ overflow:auto; flex:1; }
`;
Object.assign(__ds_scope, { Panel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/layout/Panel.jsx", error: String((e && e.message) || e) }); }

// components/layout/Tabs.jsx
try { (() => {
/**
 * Tabs — underline-style tab bar. Used in the Inspector (Propriedades /
 * Estilo / Avançado) and across settings screens.
 */
function Tabs({
  tabs = [],
  value,
  onChange,
  size = 'md'
}) {
  React.useEffect(() => {
    if (document.getElementById('dv-tabs-css')) return;
    const el = document.createElement('style');
    el.id = 'dv-tabs-css';
    el.textContent = TABS_CSS;
    document.head.appendChild(el);
  }, []);
  return /*#__PURE__*/React.createElement("div", {
    className: `dv-tabs dv-tabs--${size}`,
    role: "tablist"
  }, tabs.map(t => {
    const tab = typeof t === 'string' ? {
      value: t,
      label: t
    } : t;
    const on = tab.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: tab.value,
      type: "button",
      role: "tab",
      "aria-selected": on,
      className: `dv-tabs__tab ${on ? 'is-on' : ''}`,
      onClick: () => onChange && onChange(tab.value)
    }, tab.icon && /*#__PURE__*/React.createElement("span", {
      className: "dv-tabs__icon"
    }, tab.icon), tab.label, tab.count != null && /*#__PURE__*/React.createElement("span", {
      className: "dv-tabs__count"
    }, tab.count));
  }));
}
const TABS_CSS = `
.dv-tabs{ display:flex; align-items:stretch; gap:var(--space-2); border-bottom:1px solid var(--border-subtle); }
.dv-tabs__tab{ position:relative; display:inline-flex; align-items:center; gap:var(--space-3);
  border:none; background:transparent; cursor:pointer; color:var(--text-muted);
  font-family:var(--font-sans); font-weight:var(--fw-medium); padding:0 var(--space-5) var(--space-4);
  margin-bottom:-1px; transition:color var(--dur-fast) var(--ease-out); }
.dv-tabs--sm .dv-tabs__tab{ font-size:var(--fs-sm); padding-top:var(--space-3); }
.dv-tabs--md .dv-tabs__tab{ font-size:var(--fs-body); padding-top:var(--space-5); }
.dv-tabs__tab::after{ content:""; position:absolute; left:0; right:0; bottom:0; height:2px;
  background:var(--brand); border-radius:2px 2px 0 0; opacity:0; transform:scaleX(.4);
  transition:opacity var(--dur-fast) var(--ease-out), transform var(--dur-fast) var(--ease-out); }
.dv-tabs__tab:hover{ color:var(--text-body); }
.dv-tabs__tab.is-on{ color:var(--text-strong); font-weight:var(--fw-semibold); }
.dv-tabs__tab.is-on::after{ opacity:1; transform:scaleX(1); }
.dv-tabs__icon{ display:inline-flex; }
.dv-tabs__icon svg{ width:16px; height:16px; display:block; }
.dv-tabs__count{ font-size:var(--fs-2xs); font-weight:var(--fw-semibold); color:var(--text-subtle);
  background:var(--surface-sunken); border-radius:var(--radius-pill); padding:1px var(--space-3); }
`;
Object.assign(__ds_scope, { Tabs });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/layout/Tabs.jsx", error: String((e && e.message) || e) }); }

// ui_kits/editor/Inspector.jsx
try { (() => {
/* Inspector — properties of the selected block (right rail) */
function Inspector({
  block,
  onChange
}) {
  const {
    Panel,
    Tabs,
    PropertyRow,
    Input,
    Select,
    Switch,
    SegmentedControl,
    StateChip,
    Badge
  } = window.DrivaDesignSystem_5934aa;
  const I = window.Icon;
  const [tab, setTab] = React.useState('props');
  if (!block) {
    return /*#__PURE__*/React.createElement("aside", {
      className: "dv-inspector dv-inspector--empty"
    }, /*#__PURE__*/React.createElement("div", {
      className: "dv-inspector__placeholder"
    }, /*#__PURE__*/React.createElement("span", {
      className: "dv-inspector__phic"
    }, /*#__PURE__*/React.createElement(I, {
      name: "sliders",
      size: 20
    })), /*#__PURE__*/React.createElement("strong", null, "Nenhum bloco selecionado"), /*#__PURE__*/React.createElement("span", null, "Selecione um bloco na p\xE1gina para editar suas propriedades.")));
  }
  const set = (k, v) => onChange(block.id, {
    ...block.props,
    [k]: v
  });
  const p = block.props;
  const fields = {
    banner: () => /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(PropertyRow, {
      label: "T\xEDtulo"
    }, /*#__PURE__*/React.createElement(Input, {
      value: p.title,
      onChange: e => set('title', e.target.value),
      size: "sm"
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Subt\xEDtulo"
    }, /*#__PURE__*/React.createElement(Input, {
      value: p.subtitle,
      onChange: e => set('subtitle', e.target.value),
      size: "sm"
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Bot\xE3o (CTA)"
    }, /*#__PURE__*/React.createElement(Input, {
      value: p.cta,
      onChange: e => set('cta', e.target.value),
      size: "sm"
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Tom",
      layout: "inline"
    }, /*#__PURE__*/React.createElement(Select, {
      value: p.tone,
      options: ['brand', 'dark', 'accent'],
      size: "sm",
      onChange: e => set('tone', e.target.value)
    }))),
    carousel: () => /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Itens",
      layout: "inline"
    }, /*#__PURE__*/React.createElement(Input, {
      type: "number",
      value: p.items,
      onChange: e => set('items', +e.target.value),
      size: "sm"
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Altura",
      layout: "inline"
    }, /*#__PURE__*/React.createElement(Select, {
      value: p.height,
      options: ['Baixo', 'Médio', 'Alto'],
      size: "sm",
      onChange: e => set('height', e.target.value)
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Autoplay"
    }, /*#__PURE__*/React.createElement(Switch, {
      checked: p.autoplay,
      onChange: v => set('autoplay', v),
      label: "Avan\xE7ar automaticamente",
      size: "sm"
    }))),
    image: () => /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Ajuste",
      layout: "inline"
    }, /*#__PURE__*/React.createElement(Select, {
      value: p.fit,
      options: ['cover', 'contain', 'fill'],
      size: "sm",
      onChange: e => set('fit', e.target.value)
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Propor\xE7\xE3o",
      layout: "inline"
    }, /*#__PURE__*/React.createElement(Select, {
      value: p.ratio,
      options: ['1:1', '4:3', '16:9'],
      size: "sm",
      onChange: e => set('ratio', e.target.value)
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Legenda"
    }, /*#__PURE__*/React.createElement(Input, {
      value: p.caption,
      placeholder: "Opcional",
      onChange: e => set('caption', e.target.value),
      size: "sm"
    }))),
    product_list: () => /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Fonte de dados",
      bound: true,
      hint: "Par\xE2metros definidos no widget (I3)"
    }, /*#__PURE__*/React.createElement(Select, {
      value: p.source,
      options: ['products', 'catalog', 'featured'],
      size: "sm",
      onChange: e => set('source', e.target.value)
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Colunas",
      layout: "inline"
    }, /*#__PURE__*/React.createElement(SegmentedControl, {
      value: String(p.columns),
      onChange: v => set('columns', +v),
      options: ['1', '2', '3']
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Qtd. de itens",
      layout: "inline"
    }, /*#__PURE__*/React.createElement(Input, {
      type: "number",
      value: p.count,
      onChange: e => set('count', +e.target.value),
      size: "sm"
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Pre\xE7o"
    }, /*#__PURE__*/React.createElement(Switch, {
      checked: p.showPrice,
      onChange: v => set('showPrice', v),
      label: "Exibir pre\xE7o",
      size: "sm"
    }))),
    card: () => /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(PropertyRow, {
      label: "T\xEDtulo"
    }, /*#__PURE__*/React.createElement(Input, {
      value: p.title,
      onChange: e => set('title', e.target.value),
      size: "sm"
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Texto"
    }, /*#__PURE__*/React.createElement(Input, {
      value: p.body,
      onChange: e => set('body', e.target.value),
      size: "sm"
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "\xCDcone",
      layout: "inline"
    }, /*#__PURE__*/React.createElement(Select, {
      value: p.icon,
      options: ['star', 'zap', 'clock', 'bell'],
      size: "sm",
      onChange: e => set('icon', e.target.value)
    }))),
    text: () => /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Conte\xFAdo"
    }, /*#__PURE__*/React.createElement(Input, {
      value: p.content,
      onChange: e => set('content', e.target.value),
      size: "sm"
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Alinhamento"
    }, /*#__PURE__*/React.createElement(SegmentedControl, {
      value: p.align,
      onChange: v => set('align', v),
      fill: true,
      options: [{
        value: 'left',
        label: 'Esq.'
      }, {
        value: 'center',
        label: 'Centro'
      }, {
        value: 'right',
        label: 'Dir.'
      }]
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Estilo",
      layout: "inline"
    }, /*#__PURE__*/React.createElement(Select, {
      value: p.size,
      options: ['Título', 'Corpo'],
      size: "sm",
      onChange: e => set('size', e.target.value)
    }))),
    button: () => /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(PropertyRow, {
      label: "R\xF3tulo"
    }, /*#__PURE__*/React.createElement(Input, {
      value: p.label,
      onChange: e => set('label', e.target.value),
      size: "sm"
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Variante"
    }, /*#__PURE__*/React.createElement(SegmentedControl, {
      value: p.variant,
      onChange: v => set('variant', v),
      fill: true,
      options: [{
        value: 'primary',
        label: 'Primário'
      }, {
        value: 'secondary',
        label: 'Secund.'
      }]
    })), /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Largura"
    }, /*#__PURE__*/React.createElement(Switch, {
      checked: p.fullWidth,
      onChange: v => set('fullWidth', v),
      label: "Largura total",
      size: "sm"
    }))),
    spacer: () => /*#__PURE__*/React.createElement(PropertyRow, {
      label: "Altura",
      hint: p.size + 'px',
      layout: "inline"
    }, /*#__PURE__*/React.createElement(Input, {
      type: "number",
      value: p.size,
      onChange: e => set('size', +e.target.value),
      size: "sm",
      suffix: "px"
    }))
  };
  return /*#__PURE__*/React.createElement("aside", {
    className: "dv-inspector"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-inspector__head"
  }, /*#__PURE__*/React.createElement("span", {
    className: "dv-inspector__ic"
  }, /*#__PURE__*/React.createElement(I, {
    name: block.icon,
    size: 16
  })), /*#__PURE__*/React.createElement("div", {
    className: "dv-inspector__id"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-inspector__name"
  }, block.name), /*#__PURE__*/React.createElement("code", {
    className: "dv-inspector__slug"
  }, block.slug, "@v", block.version)), /*#__PURE__*/React.createElement(Badge, {
    tone: "neutral"
  }, block.id)), /*#__PURE__*/React.createElement("div", {
    className: "dv-inspector__tabs"
  }, /*#__PURE__*/React.createElement(Tabs, {
    value: tab,
    onChange: setTab,
    size: "sm",
    tabs: [{
      value: 'props',
      label: 'Propriedades'
    }, {
      value: 'style',
      label: 'Estilo'
    }, {
      value: 'adv',
      label: 'Avançado'
    }]
  })), /*#__PURE__*/React.createElement("div", {
    className: "dv-inspector__body"
  }, tab === 'props' && /*#__PURE__*/React.createElement("div", {
    className: "dv-fields"
  }, (fields[block.slug] || (() => null))()), tab === 'style' && /*#__PURE__*/React.createElement("div", {
    className: "dv-inspector__soon"
  }, /*#__PURE__*/React.createElement(I, {
    name: "settings",
    size: 18
  }), " Estilo e espa\xE7amento \u2014 pr\xF3ximo incremento."), tab === 'adv' && /*#__PURE__*/React.createElement("div", {
    className: "dv-fields"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-eyebrow",
    style: {
      marginBottom: 8
    }
  }, "Estados do componente (I3)"), /*#__PURE__*/React.createElement("div", {
    className: "dv-statewrap"
  }, ['idle', 'loading', 'success', 'error', 'empty'].map(s => /*#__PURE__*/React.createElement(StateChip, {
    key: s,
    state: s,
    active: s === 'success'
  }))))));
}
Object.assign(window, {
  Inspector
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/editor/Inspector.jsx", error: String((e && e.message) || e) }); }

// ui_kits/editor/Organization.jsx
try { (() => {
/* Organization — ordered page blocks (selectable, reorder, remove) */
function Organization({
  blocks,
  selectedId,
  onSelect,
  onRemove,
  onMove,
  onToggleHidden,
  onAddFirst,
  onDropSlug
}) {
  const {
    BlockRow,
    IconButton
  } = window.DrivaDesignSystem_5934aa;
  const I = window.Icon;
  const [over, setOver] = React.useState(false);
  return /*#__PURE__*/React.createElement("section", {
    className: "dv-org",
    onDragOver: e => {
      e.preventDefault();
      setOver(true);
    },
    onDragLeave: () => setOver(false),
    onDrop: e => {
      e.preventDefault();
      setOver(false);
      const s = e.dataTransfer.getData('text/slug');
      if (s) onDropSlug(s);
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-org__head"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-col-title"
  }, "P\xE1gina \xB7 ", blocks.length, " blocos"), /*#__PURE__*/React.createElement("span", {
    className: "dv-org__hint"
  }, /*#__PURE__*/React.createElement(I, {
    name: "layers",
    size: 13
  }), " ordem renderizada")), /*#__PURE__*/React.createElement("div", {
    className: 'dv-org__body' + (over ? ' is-over' : '')
  }, blocks.length === 0 && /*#__PURE__*/React.createElement("button", {
    className: "dv-org__empty",
    onClick: onAddFirst
  }, /*#__PURE__*/React.createElement(I, {
    name: "plus",
    size: 20
  }), /*#__PURE__*/React.createElement("strong", null, "Arraste um widget aqui"), /*#__PURE__*/React.createElement("span", null, "ou clique para adicionar o primeiro bloco")), blocks.map((b, i) => /*#__PURE__*/React.createElement("div", {
    key: b.id,
    className: "dv-org__item"
  }, /*#__PURE__*/React.createElement(BlockRow, {
    name: b.name,
    icon: /*#__PURE__*/React.createElement(I, {
      name: b.icon,
      size: 16
    }),
    meta: b.slug + '@v' + b.version,
    selected: b.id === selectedId,
    hidden: b.hidden,
    onSelect: () => onSelect(b.id),
    onRemove: () => onRemove(b.id)
  }), /*#__PURE__*/React.createElement("div", {
    className: "dv-org__ctrl"
  }, /*#__PURE__*/React.createElement(IconButton, {
    label: "Subir",
    size: "sm",
    disabled: i === 0,
    onClick: () => onMove(b.id, -1)
  }, /*#__PURE__*/React.createElement(I, {
    name: "chevronDown",
    size: 14,
    stroke: 2
  })), /*#__PURE__*/React.createElement(IconButton, {
    label: "Descer",
    size: "sm",
    disabled: i === blocks.length - 1,
    onClick: () => onMove(b.id, 1)
  }, /*#__PURE__*/React.createElement(I, {
    name: "chevronDown",
    size: 14
  })), /*#__PURE__*/React.createElement(IconButton, {
    label: b.hidden ? 'Mostrar' : 'Ocultar',
    size: "sm",
    active: b.hidden,
    onClick: () => onToggleHidden(b.id)
  }, /*#__PURE__*/React.createElement(I, {
    name: b.hidden ? 'eyeOff' : 'eye',
    size: 14
  }))))), over && /*#__PURE__*/React.createElement("div", {
    className: "dv-org__dropline"
  })));
}
Object.assign(window, {
  Organization
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/editor/Organization.jsx", error: String((e && e.message) || e) }); }

// ui_kits/editor/Palette.jsx
try { (() => {
/* Palette — searchable, categorized widget tiles (left rail) */
function Palette({
  onAdd
}) {
  const {
    WidgetTile,
    Input
  } = window.DrivaDesignSystem_5934aa;
  const I = window.Icon;
  const [q, setQ] = React.useState('');
  const items = window.DRIVA.CATALOG.filter(c => c.name.toLowerCase().includes(q.toLowerCase()));
  const cats = [...new Set(items.map(c => c.category))];
  return /*#__PURE__*/React.createElement("aside", {
    className: "dv-palette"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-palette__head"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-col-title"
  }, "Widgets"), /*#__PURE__*/React.createElement(Input, {
    value: q,
    onChange: e => setQ(e.target.value),
    placeholder: "Buscar widget",
    size: "sm",
    prefix: /*#__PURE__*/React.createElement(I, {
      name: "search",
      size: 15
    })
  })), /*#__PURE__*/React.createElement("div", {
    className: "dv-palette__body"
  }, cats.map(cat => /*#__PURE__*/React.createElement("div", {
    key: cat,
    className: "dv-palette__group"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-eyebrow"
  }, cat), /*#__PURE__*/React.createElement("div", {
    className: "dv-palette__grid"
  }, items.filter(c => c.category === cat).map(c => /*#__PURE__*/React.createElement(WidgetTile, {
    key: c.slug,
    name: c.name,
    icon: /*#__PURE__*/React.createElement(I, {
      name: c.icon
    }),
    onClick: () => onAdd(c.slug),
    onDragStart: e => {
      e.dataTransfer.setData('text/slug', c.slug);
    }
  }))))), items.length === 0 && /*#__PURE__*/React.createElement("div", {
    className: "dv-palette__empty"
  }, "Nenhum widget encontrado.")), /*#__PURE__*/React.createElement("div", {
    className: "dv-palette__foot"
  }, /*#__PURE__*/React.createElement(I, {
    name: "cube",
    size: 14
  }), " ", window.DRIVA.CATALOG.length, " widgets no cat\xE1logo"));
}
Object.assign(window, {
  Palette
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/editor/Palette.jsx", error: String((e && e.message) || e) }); }

// ui_kits/editor/Preview.jsx
try { (() => {
/* Preview — faithful-style device render of the page (mirrors sdui_flutter) */
function Preview({
  blocks,
  device,
  selectedId,
  onSelect
}) {
  const I = window.Icon;
  const SW = window.DRIVA.SWATCHES;
  const frame = {
    iphone: {
      w: 300,
      label: 'iPhone 15 · 393pt'
    },
    android: {
      w: 300,
      label: 'Pixel 8 · 412dp'
    },
    tablet: {
      w: 420,
      label: 'iPad · 820pt'
    }
  }[device];
  const visible = blocks.filter(b => !b.hidden);
  function renderBlock(b) {
    const sel = b.id === selectedId;
    const wrap = node => /*#__PURE__*/React.createElement("div", {
      key: b.id,
      className: 'pv-block' + (sel ? ' is-sel' : ''),
      onClick: () => onSelect(b.id)
    }, node);
    const p = b.props;
    switch (b.slug) {
      case 'banner':
        return wrap(/*#__PURE__*/React.createElement("div", {
          className: "pv-banner"
        }, /*#__PURE__*/React.createElement("div", {
          className: "pv-banner__txt"
        }, /*#__PURE__*/React.createElement("div", {
          className: "pv-banner__title"
        }, p.title), /*#__PURE__*/React.createElement("div", {
          className: "pv-banner__sub"
        }, p.subtitle), /*#__PURE__*/React.createElement("span", {
          className: "pv-banner__cta"
        }, p.cta))));
      case 'carousel':
        return wrap(/*#__PURE__*/React.createElement("div", {
          className: "pv-carousel"
        }, Array.from({
          length: Math.min(p.items, 4)
        }).map((_, i) => /*#__PURE__*/React.createElement("div", {
          className: "pv-carousel__slide",
          key: i,
          style: {
            background: SW[i % SW.length]
          }
        }))));
      case 'image':
        return wrap(/*#__PURE__*/React.createElement("div", {
          className: "pv-image",
          style: {
            background: SW[0]
          }
        }, /*#__PURE__*/React.createElement(I, {
          name: "image",
          size: 22
        })));
      case 'product_list':
        return wrap(/*#__PURE__*/React.createElement("div", {
          className: "pv-grid",
          style: {
            gridTemplateColumns: `repeat(${p.columns}, 1fr)`
          }
        }, Array.from({
          length: p.count
        }).map((_, i) => /*#__PURE__*/React.createElement("div", {
          className: "pv-prod",
          key: i
        }, /*#__PURE__*/React.createElement("div", {
          className: "pv-prod__img",
          style: {
            background: SW[i % SW.length]
          }
        }), /*#__PURE__*/React.createElement("div", {
          className: "pv-prod__name"
        }), p.showPrice && /*#__PURE__*/React.createElement("div", {
          className: "pv-prod__price"
        }, "R$ ", 49 + i * 30, ",90")))));
      case 'card':
        return wrap(/*#__PURE__*/React.createElement("div", {
          className: "pv-card"
        }, /*#__PURE__*/React.createElement("div", {
          className: "pv-card__ic"
        }, /*#__PURE__*/React.createElement(I, {
          name: p.icon,
          size: 18
        })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
          className: "pv-card__title"
        }, p.title), /*#__PURE__*/React.createElement("div", {
          className: "pv-card__body"
        }, p.body))));
      case 'text':
        return wrap(/*#__PURE__*/React.createElement("div", {
          className: 'pv-text pv-text--' + p.align,
          style: {
            fontSize: p.size === 'Título' ? 18 : 13,
            fontWeight: p.size === 'Título' ? 700 : 400
          }
        }, p.content));
      case 'button':
        return wrap(/*#__PURE__*/React.createElement("div", {
          className: "pv-btnwrap"
        }, /*#__PURE__*/React.createElement("span", {
          className: 'pv-btn pv-btn--' + p.variant,
          style: {
            width: p.fullWidth ? '100%' : 'auto'
          }
        }, p.label)));
      case 'spacer':
        return wrap(/*#__PURE__*/React.createElement("div", {
          className: "pv-spacer",
          style: {
            height: p.size
          }
        }, /*#__PURE__*/React.createElement("span", null, p.size, "px")));
      default:
        return wrap(/*#__PURE__*/React.createElement("div", {
          className: "pv-unknown"
        }, b.name));
    }
  }
  return /*#__PURE__*/React.createElement("div", {
    className: "dv-preview"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-preview__bar"
  }, /*#__PURE__*/React.createElement("span", {
    className: "dv-preview__live"
  }, /*#__PURE__*/React.createElement("span", {
    className: "dv-livedot"
  }), " Preview fiel"), /*#__PURE__*/React.createElement("span", {
    className: "dv-preview__device"
  }, frame.label)), /*#__PURE__*/React.createElement("div", {
    className: "dv-preview__stage"
  }, /*#__PURE__*/React.createElement("div", {
    className: 'dv-phone dv-phone--' + device,
    style: {
      width: frame.w
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-phone__notch"
  }), /*#__PURE__*/React.createElement("div", {
    className: "dv-phone__status"
  }, /*#__PURE__*/React.createElement("span", null, "9:41"), /*#__PURE__*/React.createElement("span", {
    className: "dv-phone__icons"
  }, /*#__PURE__*/React.createElement(I, {
    name: "bell",
    size: 11
  }))), /*#__PURE__*/React.createElement("div", {
    className: "dv-phone__screen"
  }, visible.length === 0 ? /*#__PURE__*/React.createElement("div", {
    className: "dv-phone__empty"
  }, "P\xE1gina vazia") : visible.map(renderBlock)))));
}
Object.assign(window, {
  Preview
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/editor/Preview.jsx", error: String((e && e.message) || e) }); }

// ui_kits/editor/Topbar.jsx
try { (() => {
/* Topbar — page identity, save status, device toggle, preview & publish */
function Topbar({
  meta,
  stage,
  saved,
  device,
  onDevice,
  onPublish,
  blockCount
}) {
  const {
    Button,
    IconButton,
    StageBadge,
    Avatar,
    SegmentedControl
  } = window.DrivaDesignSystem_5934aa;
  const I = window.Icon;
  return /*#__PURE__*/React.createElement("header", {
    className: "dv-topbar"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dv-topbar__left"
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/driva-mark.svg",
    width: "28",
    height: "28",
    alt: "Driva"
  }), /*#__PURE__*/React.createElement("div", {
    className: "dv-topbar__crumb"
  }, /*#__PURE__*/React.createElement("span", {
    className: "dv-topbar__project"
  }, meta.project), /*#__PURE__*/React.createElement(I, {
    name: "chevronRight",
    size: 14
  }), /*#__PURE__*/React.createElement("span", {
    className: "dv-topbar__page"
  }, meta.page), /*#__PURE__*/React.createElement("code", {
    className: "dv-topbar__slug"
  }, meta.slug)), /*#__PURE__*/React.createElement(StageBadge, {
    stage: stage,
    size: "sm"
  })), /*#__PURE__*/React.createElement("div", {
    className: "dv-topbar__center"
  }, /*#__PURE__*/React.createElement(SegmentedControl, {
    value: device,
    onChange: onDevice,
    options: [{
      value: 'iphone',
      icon: /*#__PURE__*/React.createElement(I, {
        name: "smartphone",
        size: 15
      }),
      title: 'iPhone'
    }, {
      value: 'android',
      icon: /*#__PURE__*/React.createElement(I, {
        name: "smartphone",
        size: 15
      }),
      title: 'Android'
    }, {
      value: 'tablet',
      icon: /*#__PURE__*/React.createElement(I, {
        name: "tablet",
        size: 15
      }),
      title: 'Tablet'
    }]
  })), /*#__PURE__*/React.createElement("div", {
    className: "dv-topbar__right"
  }, /*#__PURE__*/React.createElement("span", {
    className: "dv-topbar__save"
  }, saved ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(I, {
    name: "check",
    size: 14
  }), " Salvo") : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", {
    className: "dv-dotpulse"
  }), " Salvando\u2026")), /*#__PURE__*/React.createElement(IconButton, {
    label: "Desfazer"
  }, /*#__PURE__*/React.createElement(I, {
    name: "undo"
  })), /*#__PURE__*/React.createElement(IconButton, {
    label: "Refazer"
  }, /*#__PURE__*/React.createElement(I, {
    name: "redo"
  })), /*#__PURE__*/React.createElement("span", {
    className: "dv-topbar__sep"
  }), /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    size: "sm",
    iconLeft: /*#__PURE__*/React.createElement(I, {
      name: "play",
      size: 15
    })
  }, "Pr\xE9-visualizar"), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    size: "sm",
    iconLeft: /*#__PURE__*/React.createElement(I, {
      name: "zap",
      size: 15
    }),
    onClick: onPublish
  }, "Publicar"), /*#__PURE__*/React.createElement(Avatar, {
    name: "Euclides Gomes",
    size: "sm"
  })));
}
Object.assign(window, {
  Topbar
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/editor/Topbar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/editor/app.jsx
try { (() => {
/* Editor — state container wiring the four columns together */
function Editor() {
  const D = window.DRIVA;
  const [blocks, setBlocks] = React.useState(() => D.initialBlocks());
  const [selectedId, setSelectedId] = React.useState(null);
  const [device, setDevice] = React.useState('iphone');
  const [saved, setSaved] = React.useState(true);
  const [toast, setToast] = React.useState(null);
  const {
    Button
  } = window.DrivaDesignSystem_5934aa;
  const I = window.Icon;

  // mark dirty then auto-"save"
  const touch = React.useCallback(() => {
    setSaved(false);
    clearTimeout(window.__dvSave);
    window.__dvSave = setTimeout(() => setSaved(true), 900);
  }, []);
  const add = slug => {
    const b = D.makeBlock(slug);
    setBlocks(prev => [...prev, b]);
    setSelectedId(b.id);
    touch();
  };
  const remove = id => {
    setBlocks(prev => prev.filter(b => b.id !== id));
    setSelectedId(s => s === id ? null : s);
    touch();
  };
  const move = (id, dir) => {
    setBlocks(prev => {
      const i = prev.findIndex(b => b.id === id);
      const j = i + dir;
      if (j < 0 || j >= prev.length) return prev;
      const next = prev.slice();
      [next[i], next[j]] = [next[j], next[i]];
      return next;
    });
    touch();
  };
  const toggleHidden = id => {
    setBlocks(prev => prev.map(b => b.id === id ? {
      ...b,
      hidden: !b.hidden
    } : b));
    touch();
  };
  const changeProps = (id, props) => {
    setBlocks(prev => prev.map(b => b.id === id ? {
      ...b,
      props
    } : b));
    touch();
  };
  const publish = () => {
    setToast({
      kind: 'review',
      msg: 'Enviado para homologação'
    });
    setTimeout(() => setToast(null), 2600);
  };
  const selected = blocks.find(b => b.id === selectedId) || null;
  return /*#__PURE__*/React.createElement("div", {
    className: "dv-editor"
  }, /*#__PURE__*/React.createElement(Topbar, {
    meta: D.META,
    stage: "draft",
    saved: saved,
    device: device,
    onDevice: setDevice,
    onPublish: publish,
    blockCount: blocks.length
  }), /*#__PURE__*/React.createElement("div", {
    className: "dv-workspace"
  }, /*#__PURE__*/React.createElement(Palette, {
    onAdd: add
  }), /*#__PURE__*/React.createElement(Organization, {
    blocks: blocks,
    selectedId: selectedId,
    onSelect: setSelectedId,
    onRemove: remove,
    onMove: move,
    onToggleHidden: toggleHidden,
    onAddFirst: () => add('banner'),
    onDropSlug: add
  }), /*#__PURE__*/React.createElement(Preview, {
    blocks: blocks,
    device: device,
    selectedId: selectedId,
    onSelect: setSelectedId
  }), /*#__PURE__*/React.createElement(Inspector, {
    block: selected,
    onChange: changeProps
  })), toast && /*#__PURE__*/React.createElement("div", {
    className: "dv-toast"
  }, /*#__PURE__*/React.createElement("span", {
    className: "dv-toast__ic"
  }, /*#__PURE__*/React.createElement(I, {
    name: "check",
    size: 16
  })), toast.msg));
}
ReactDOM.createRoot(document.getElementById('root')).render(/*#__PURE__*/React.createElement(Editor, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/editor/app.jsx", error: String((e && e.message) || e) }); }

// ui_kits/editor/data.js
try { (() => {
/* ============================================================
   Driva editor UI kit — catalog + sample data
   Exposes window.DRIVA with the widget catalog, block factory,
   and preview content. Plain JS (loaded before the babel app).
   ============================================================ */
(function () {
  // Widget catalog that populates the palette (Decision I1.1: curated sections)
  const CATALOG = [{
    slug: 'banner',
    name: 'Banner',
    icon: 'banner',
    category: 'Mídia',
    version: 2
  }, {
    slug: 'carousel',
    name: 'Carrossel',
    icon: 'carousel',
    category: 'Mídia',
    version: 1
  }, {
    slug: 'image',
    name: 'Imagem',
    icon: 'image',
    category: 'Mídia',
    version: 1
  }, {
    slug: 'product_list',
    name: 'Lista de itens',
    icon: 'list',
    category: 'Dados',
    version: 1
  }, {
    slug: 'card',
    name: 'Card',
    icon: 'card',
    category: 'Conteúdo',
    version: 1
  }, {
    slug: 'text',
    name: 'Texto',
    icon: 'type',
    category: 'Conteúdo',
    version: 1
  }, {
    slug: 'button',
    name: 'Botão',
    icon: 'button',
    category: 'Ações',
    version: 1
  }, {
    slug: 'spacer',
    name: 'Espaçador',
    icon: 'spacer',
    category: 'Layout',
    version: 1
  }];
  const CAT_BY_SLUG = Object.fromEntries(CATALOG.map(c => [c.slug, c]));

  // Default props per widget type
  const DEFAULTS = {
    banner: {
      title: 'Promoção de inverno',
      subtitle: 'Até 40% OFF',
      cta: 'Ver ofertas',
      tone: 'brand'
    },
    carousel: {
      items: 3,
      height: 'Médio',
      autoplay: true
    },
    image: {
      fit: 'cover',
      ratio: '16:9',
      caption: ''
    },
    product_list: {
      source: 'products',
      columns: 2,
      count: 4,
      showPrice: true
    },
    card: {
      title: 'Frete grátis',
      body: 'Em compras acima de R$ 199',
      icon: 'star'
    },
    text: {
      content: 'Bem-vindo à nossa loja',
      align: 'center',
      size: 'Título'
    },
    button: {
      label: 'Comprar agora',
      variant: 'primary',
      fullWidth: true
    },
    spacer: {
      size: 24
    }
  };
  let _id = 100;
  function makeBlock(slug) {
    const cat = CAT_BY_SLUG[slug];
    return {
      id: 'b' + ++_id,
      slug,
      name: cat.name,
      icon: cat.icon,
      version: cat.version,
      hidden: false,
      props: JSON.parse(JSON.stringify(DEFAULTS[slug] || {}))
    };
  }

  // The page the editor opens with
  function initialBlocks() {
    const b = ['banner', 'product_list', 'card', 'button'].map(makeBlock);
    b[0].props.title = 'Promoção de inverno';
    return b;
  }

  // Sample product imagery (solid swatches — no external assets needed)
  const SWATCHES = ['#dbe7ff', '#ffe6d6', '#dcf3e8', '#f0e4ff', '#ffe1ec', '#e2f1ff'];
  window.DRIVA = {
    CATALOG,
    CAT_BY_SLUG,
    DEFAULTS,
    makeBlock,
    initialBlocks,
    SWATCHES,
    META: {
      project: 'Loja Demo',
      page: 'Home',
      slug: '/home'
    }
  };
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/editor/data.js", error: String((e && e.message) || e) }); }

__ds_ns.BlockRow = __ds_scope.BlockRow;

__ds_ns.PropertyRow = __ds_scope.PropertyRow;

__ds_ns.StageBadge = __ds_scope.StageBadge;

__ds_ns.StateChip = __ds_scope.StateChip;

__ds_ns.WidgetTile = __ds_scope.WidgetTile;

__ds_ns.Avatar = __ds_scope.Avatar;

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.Tooltip = __ds_scope.Tooltip;

__ds_ns.Checkbox = __ds_scope.Checkbox;

__ds_ns.Input = __ds_scope.Input;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.Select = __ds_scope.Select;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.Textarea = __ds_scope.Textarea;

__ds_ns.Panel = __ds_scope.Panel;

__ds_ns.Tabs = __ds_scope.Tabs;

})();
