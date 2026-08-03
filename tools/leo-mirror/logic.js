
class Component extends DCLogic {
  state = {
    d: null, err: null, rate: 3.6, scen: this.props.defaultScenario || 'base',
    plain: !!this.props.plainEnglishDefault, gloss: false, tour: false, step: 0,
    math: {}, acc: {}, kpiDom: 'All', kpiStat: 'All', kpiSort: 'domain',
    rrSort: 'exposure', pins: [], active: 'ch1'
  };

  C = { acc: '#9184d9', acc2: '#b5abfc', accD: '#5d5294', accDD: '#423a6a', bad: 'oklch(0.72 0.13 22)', good: 'oklch(0.74 0.105 155)', warn: 'oklch(0.78 0.125 82)', mut: '#75798c', dim: '#9397ab', txt: '#e9e9ed', line: '#3f424d' };

  TOUR = [
    { id: 's-hero', t: 'The gap is the whole story', n: "Two lines. One is how many satellites the factory could have built at its own stated rate. The other is how many are actually in orbit. Everything else on this page is a consequence of the space between them." },
    { id: 's-milestone', t: 'The deadline is not negotiable', n: "An FCC licence condition requires a satellite count by a date. Drag the assumed deployment rate — the projection, the shortfall, and every modelled number further down this page move with it." },
    { id: 's-capacity', t: 'Manufacturing was never the constraint', n: "Peak realised pace against the factory ceiling. A gap here says the bottleneck is launch supply, not the production line — which changes which lever finance should be pricing." },
    { id: 's-cost', t: 'The bill has moved', n: "Two metric types kept strictly apart: the cumulative programme estimate over time, and a single-year headwind disclosed separately. Adding them would double-count." },
    { id: 's-op', t: 'Now the plan', n: "Chapter 2 is the FP&A toolkit itself — multi-year OpEx/CapEx/headcount, ROI, TCO, rolling variance. Illustrative shapes, real methodology." },
    { id: 's-cash', t: 'Drill all the way down', n: "Seven categories, twenty-one subcategories, plan against actual. Click any category to open it — this is the level a programme actually gets walked at." },
    { id: 's-evm', t: 'Earned value, in plain terms', n: "CPI below 1.0 means you are getting less value than you are paying for. SPI below 1.0 means you are behind schedule. Both are true here, and the EAC follows." },
    { id: 's-eac', t: 'How wrong could the forecast be', n: "One driver swung at a time, the other held at actual. This is the honest range around the estimate at completion — not a single confident number." },
    { id: 's-launch', t: 'Why the gap exists', n: "Chapter 3. Amazon's own filing says it is producing satellites faster than others can launch them. Here are the events behind that sentence." },
    { id: 's-inv', t: 'The inventory nobody has priced', n: "Built-but-unlaunched satellites as a range rather than a false-precision number — then translated into a carrying value that rolls forward." },
    { id: 's-risk', t: 'One number, five signals', n: "A rule-based composite weighted 30/25/20/15/10. Not a fabricated failure probability — a tier, with every input visible and traceable." },
    { id: 's-90day', t: 'What I would actually do', n: "Chapter 4. Seven workstreams, each with one accountable role, a measurable target, and a finance deliverable attached to it." }
  ];

  componentDidMount() {
    var __marts = (window.__resources && window.__resources.martsData) || 'leo_finance_dashboard_data.json';
    fetch(__marts).then(r => r.json()).then(d => {
      this.setState({ d: d, rate: this.rateFor(this.state.scen, d) }, () => this.afterData());
    }).catch(e => this.setState({ err: String(e && e.message || e) }));
    this._key = e => {
      if (!this.state.tour) return;
      if (e.key === 'ArrowRight') { e.preventDefault(); this.go(1); }
      if (e.key === 'ArrowLeft') { e.preventDefault(); this.go(-1); }
      if (e.key === 'Escape') this.setState({ tour: false });
    };
    window.addEventListener('keydown', this._key);
    this.reveal();
    this.scrollSpy();
    this.measureOverlay();
    this._fb = setTimeout(() => {
      var r = this.root(); if (r) Array.prototype.forEach.call(r.querySelectorAll('[data-reveal]'), function (el) { el.setAttribute('data-in', ''); });
    }, 3200);
  }

  componentWillUnmount() {
    window.removeEventListener('keydown', this._key);
    window.removeEventListener('scroll', this._scroll);
    if (this._io) this._io.disconnect();
    if (this._ro) this._ro.disconnect();
    clearTimeout(this._fb);
  }

  componentDidUpdate() { this.reveal(); this.counters(); this.measureOverlay(); }

  measureOverlay() {
    var el = document.querySelector('[data-overlay]');
    if (!el) return;
    var h = Math.ceil(el.getBoundingClientRect().height);
    if (h === this._oh) return;
    this._oh = h;
    document.documentElement.style.setProperty('--leo-overlay-h', h + 'px');
    if (!this._ro && window.ResizeObserver) {
      var self = this;
      this._ro = new ResizeObserver(function () { self.measureOverlay(); });
      this._ro.observe(el);
    }
  }

  root() { return document.querySelector('[data-leo-root]'); }

  reveal() {
    var r = this.root(); if (!r) return;
    var self = this;
    if (this.props.motion === 'reduced') {
      Array.prototype.forEach.call(r.querySelectorAll('[data-reveal]'), function (el) { el.setAttribute('data-in', ''); });
      return;
    }
    if (!this._io) {
      this._io = new IntersectionObserver(function (es) {
        es.forEach(function (en) { if (en.isIntersecting) { en.target.setAttribute('data-in', ''); self._io.unobserve(en.target); } });
      }, { rootMargin: '0px 0px -8% 0px', threshold: 0.03 });
    }
    Array.prototype.forEach.call(r.querySelectorAll('[data-reveal]'), function (el) {
      if (!el.__ob) { el.__ob = 1; self._io.observe(el); }
    });
  }

  afterData() { var self = this; requestAnimationFrame(function () { self.reveal(); self.counters(); }); }

  counters() {
    if (this.props.motion === 'reduced') return;
    var r = this.root(); if (!r) return;
    var self = this;
    if (!this._co) {
      this._co = new IntersectionObserver(function (es) {
        es.forEach(function (en) { if (en.isIntersecting) { self._co.unobserve(en.target); self.run(en.target); } });
      }, { threshold: 0.35 });
    }
    Array.prototype.forEach.call(r.querySelectorAll('[data-cu]'), function (el) {
      if (!el.__cu) { el.__cu = 1; self._co.observe(el); }
    });
  }

  run(el) {
    var txt = el.textContent, m = txt.match(/-?\d[\d,]*(\.\d+)?/);
    if (!m) return;
    var target = parseFloat(m[0].replace(/,/g, ''));
    if (!isFinite(target)) return;
    var dec = m[1] ? m[1].length - 1 : 0;
    var pre = txt.slice(0, m.index), post = txt.slice(m.index + m[0].length);
    var t0 = performance.now(), dur = 950 + Math.random() * 350;
    var tick = function (now) {
      var p = Math.min(1, (now - t0) / dur), e = 1 - Math.pow(1 - p, 3);
      el.textContent = pre + (target * e).toLocaleString('en-US', { minimumFractionDigits: dec, maximumFractionDigits: dec }) + post;
      if (p < 1) requestAnimationFrame(tick); else el.textContent = txt;
    };
    requestAnimationFrame(tick);
  }

  scrollSpy() {
    var self = this, raf = 0;
    this._scroll = function () {
      if (raf) return;
      raf = requestAnimationFrame(function () {
        raf = 0;
        var r = self.root(); if (!r) return;
        var bar = r.querySelector('[data-progress]');
        var h = document.documentElement.scrollHeight - window.innerHeight;
        if (bar) bar.style.transform = 'scaleX(' + (h > 0 ? Math.min(1, window.scrollY / h) : 0) + ')';
        var act = 'ch1';
        ['ch1', 'ch2', 'ch3', 'ch4'].forEach(function (id) {
          var el = document.getElementById(id);
          if (el && el.getBoundingClientRect().top < window.innerHeight * 0.35) act = id;
        });
        if (act !== self.state.active) self.setState({ active: act });
      });
    };
    window.addEventListener('scroll', this._scroll, { passive: true });
    this._scroll();
  }

  rateFor(s, d) {
    d = d || this.state.d;
    if (!d) return this.state.rate;
    var cg = d.capacity_gap, inv = d.unlaunched_inventory;
    if (s === 'low') return Math.round(inv.deployed_count / inv.elapsed_days * 100) / 100;
    if (s === 'high') return cg.capacity_ceiling_per_day;
    return cg.realized_peak_per_day;
  }
  setScen(s) { this.setState({ scen: s, rate: this.rateFor(s) }); }

  jump(id) {
    var el = document.getElementById(id); if (!el) return;
    window.scrollTo({ top: el.getBoundingClientRect().top + window.scrollY - 96, behavior: 'smooth' });
  }
  flash(id) {
    var el = document.getElementById(id); if (!el) return;
    el.setAttribute('data-focus', '');
    setTimeout(function () { el.removeAttribute('data-focus'); }, 2400);
  }
  go(n) {
    var i = Math.max(0, Math.min(this.TOUR.length - 1, this.state.step + n)), self = this;
    this.setState({ step: i }, function () { self.jump(self.TOUR[i].id); self.flash(self.TOUR[i].id); });
  }
  startTour() {
    var self = this;
    this.setState({ tour: true, step: 0 }, function () { self.jump(self.TOUR[0].id); self.flash(self.TOUR[0].id); });
  }
  tog(k, id) {
    var o = {}; var cur = this.state[k] || {};
    Object.keys(cur).forEach(function (x) { o[x] = cur[x]; });
    o[id] = !o[id];
    var p = {}; p[k] = o; this.setState(p);
  }
  togPin(p) {
    var has = this.state.pins.indexOf(p) >= 0;
    this.setState({ pins: has ? this.state.pins.filter(function (x) { return x !== p; }) : this.state.pins.concat([p]) });
  }

  usd(n, sign) {
    if (n == null || isNaN(n)) return '—';
    var a = Math.abs(n), s = n < 0 ? '−' : (sign ? '+' : '');
    if (a >= 1e9) return s + '$' + (a / 1e9).toFixed(2) + 'B';
    if (a >= 1e6) return s + '$' + (a / 1e6).toFixed(1) + 'M';
    if (a >= 1e3) return s + '$' + Math.round(a / 1e3) + 'K';
    return s + '$' + Math.round(a);
  }
  num(n, d) { return n == null || isNaN(n) ? '—' : Number(n).toLocaleString('en-US', { minimumFractionDigits: d || 0, maximumFractionDigits: d || 0 }); }
  pc(n, d) { return n == null || isNaN(n) ? '—' : Number(n).toFixed(d == null ? 1 : d) + '%'; }
  dt(s) {
    if (!s) return '—';
    var p = String(s).slice(0, 10).split('-');
    var M = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return M[(+p[1]) - 1] + ' ' + (+p[2]) + ', ' + p[0];
  }
  md(s) { if (!s) return '—'; var p = String(s).slice(0, 10).split('-'); var M = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']; return M[(+p[1]) - 1] + " '" + p[0].slice(2); }
  dd(a, b) { return Math.round((new Date(b) - new Date(a)) / 864e5); }
  tc(s) { return String(s == null ? '' : s).replace(/_/g, ' ').replace(/\b\w/g, function (c) { return c.toUpperCase(); }); }
  tier(t) {
    var s = String(t == null ? '' : t).toLowerCase();
    if (/high|critical|at.risk|elevated|fail|breach|miss|below|behind/.test(s)) return this.C.bad;
    if (/medium|moderate|watch|monitor|caution|partial|incident/.test(s)) return this.C.warn;
    if (/low|ok|on.track|pass|met|success|clean/.test(s)) return this.C.good;
    return this.C.mut;
  }

  mkBars(groups, series, o) {
    o = o || {};
    var w = o.w || 720, h = o.h || 220, ml = o.ml || 56, mr = o.mr || 12, mt = o.mt || 14, mb = o.mb || 34;
    var iw = w - ml - mr, ih = h - mt - mb, self = this;
    var max = 0, min = 0;
    groups.forEach(function (g) { series.forEach(function (s) { var v = g.vals[s.key] || 0; if (v > max) max = v; if (v < min) min = v; }); });
    if (max === 0 && min === 0) max = 1;
    var nice = function (v) { if (!v) return 0; var p = Math.pow(10, Math.floor(Math.log10(Math.abs(v)))); return Math.ceil(v / p * 2) / 2 * p; };
    max = nice(max); min = min < 0 ? -nice(-min) : 0;
    var span = (max - min) || 1;
    var Y = function (v) { return mt + ih - ((v - min) / span) * ih; };
    var gw = iw / Math.max(1, groups.length), bw = Math.min(o.bw || 26, (gw * 0.7) / series.length);
    var bars = [], xlabels = [];
    groups.forEach(function (g, gi) {
      var cx = ml + gw * gi + gw / 2, tot = series.length * bw + (series.length - 1) * 3;
      series.forEach(function (s, si) {
        var v = g.vals[s.key] || 0, x = cx - tot / 2 + si * (bw + 3), y0 = Y(0), y1 = Y(v);
        bars.push({ key: s.key + '-' + gi, x: x, y: Math.min(y0, y1), w: bw, h: Math.max(1.5, Math.abs(y1 - y0)), fill: s.color, label: s.label, val: v, g: g.label });
      });
      xlabels.push({ key: 'x' + gi, x: cx, y: h - 12, label: g.label });
    });
    var ticks = [];
    for (var i = 0; i <= 4; i++) { var v = min + span * i / 4; ticks.push({ key: 't' + i, y: Y(v), label: o.fmt ? o.fmt(v) : self.num(Math.round(v)) }); }
    return { w: w, h: h, ml: ml, mt: mt, ih: ih, iw: iw, x2: w - mr, bars: bars, xlabels: xlabels, ticks: ticks, zero: Y(0), legend: series.map(function (s, i) { return { key: 'l' + i, label: s.label, color: s.color }; }) };
  }

  mkStack(groups, series, o) {
    o = o || {};
    var w = o.w || 720, h = o.h || 210, ml = o.ml || 56, mr = o.mr || 12, mt = o.mt || 14, mb = o.mb || 34;
    var iw = w - ml - mr, ih = h - mt - mb, self = this;
    var max = 0;
    groups.forEach(function (g) { var t = 0; series.forEach(function (s) { t += Math.max(0, g.vals[s.key] || 0); }); if (t > max) max = t; });
    if (!max) max = 1;
    var gw = iw / Math.max(1, groups.length), bw = Math.min(o.bw || 44, gw * 0.62);
    var bars = [], xlabels = [];
    groups.forEach(function (g, gi) {
      var cx = ml + gw * gi + gw / 2, acc = 0;
      series.forEach(function (s) {
        var v = Math.max(0, g.vals[s.key] || 0); if (!v) return;
        var hh = (v / max) * ih, y = mt + ih - ((acc + v) / max) * ih;
        bars.push({ key: s.key + '-' + gi, x: cx - bw / 2, y: y, w: bw, h: hh, fill: s.color, label: s.label, val: v, g: g.label });
        acc += v;
      });
      xlabels.push({ key: 'sx' + gi, x: cx, y: h - 12, label: g.label });
    });
    var ticks = [];
    for (var i = 0; i <= 4; i++) { ticks.push({ key: 'st' + i, y: mt + ih - (i / 4) * ih, label: o.fmt ? o.fmt(max * i / 4) : self.num(Math.round(max * i / 4)) }); }
    return { w: w, h: h, ml: ml, mt: mt, ih: ih, x2: w - mr, bars: bars, xlabels: xlabels, ticks: ticks, base: mt + ih, legend: series.map(function (s, i) { return { key: 'sl' + i, label: s.label, color: s.color }; }) };
  }

  mkLines(xs, series, o) {
    o = o || {};
    var w = o.w || 720, h = o.h || 220, ml = o.ml || 60, mr = o.mr || 16, mt = o.mt || 16, mb = o.mb || 34;
    var iw = w - ml - mr, ih = h - mt - mb, self = this;
    var max = o.max != null ? o.max : -Infinity, min = o.min != null ? o.min : Infinity;
    if (o.max == null) { series.forEach(function (s) { s.vals.forEach(function (v) { if (v != null && v > max) max = v; }); }); }
    if (o.min == null) { series.forEach(function (s) { s.vals.forEach(function (v) { if (v != null && v < min) min = v; }); }); if (min > 0) min = 0; }
    if (!isFinite(max)) max = 1; if (!isFinite(min)) min = 0;
    if (max === min) max = min + 1;
    if (o.max == null) max = max + (max - min) * 0.1;
    var n = xs.length;
    var X = function (i) { return n <= 1 ? ml + iw / 2 : ml + (iw * i) / (n - 1); };
    var Y = function (v) { return mt + ih - ((v - min) / (max - min)) * ih; };
    var paths = [], dots = [];
    series.forEach(function (s) {
      var dstr = '', prev = false, pts = [];
      s.vals.forEach(function (v, i) {
        if (v == null) { prev = false; return; }
        dstr += (prev ? ' L ' : ' M ') + X(i).toFixed(1) + ' ' + Y(v).toFixed(1);
        prev = true; pts.push([X(i), Y(v)]);
        dots.push({ key: s.key + '-' + i, x: X(i), y: Y(v), color: s.color, r: o.r || 3.4 });
      });
      var area = '';
      if (s.area && pts.length) {
        var base = Y(Math.max(min, 0));
        area = 'M ' + pts.map(function (p) { return p[0].toFixed(1) + ' ' + p[1].toFixed(1); }).join(' L ') + ' L ' + pts[pts.length - 1][0].toFixed(1) + ' ' + base.toFixed(1) + ' L ' + pts[0][0].toFixed(1) + ' ' + base.toFixed(1) + ' Z';
      }
      paths.push({ key: s.key, d: dstr.trim(), color: s.color, label: s.label, area: area, dash: s.dash || '0', width: s.width || 2, solid: !s.dash });
    });
    var ticks = [];
    for (var i = 0; i <= 4; i++) { var v = min + (max - min) * i / 4; ticks.push({ key: 'lt' + i, y: Y(v), label: o.fmt ? o.fmt(v) : self.num(Math.round(v)) }); }
    return { w: w, h: h, ml: ml, mt: mt, ih: ih, x2: w - mr, paths: paths, dots: dots, ticks: ticks, base: mt + ih, xlabels: xs.map(function (l, i) { return { key: 'lx' + i, x: X(i), y: h - 12, label: l }; }), legend: series.map(function (s, i) { return { key: 'll' + i, label: s.label, color: s.color, dash: s.dash || '0' }; }) };
  }

  renderVals() {
    var S = this.state, d = S.d, C = this.C, self = this;
    var V = {
      loading: !d, ready: !!d, err: S.err, hasErr: !!S.err,
      plain: S.plain, notPlain: !S.plain, gloss: S.gloss, tour: S.tour,
      act: { ch1: S.active === 'ch1', ch2: S.active === 'ch2', ch3: S.active === 'ch3', ch4: S.active === 'ch4' },
      sc: { low: S.scen === 'low', base: S.scen === 'base', high: S.scen === 'high', custom: S.scen === 'custom' },
      onPlain: function () { self.setState({ plain: !S.plain }); },
      onGloss: function () { self.setState({ gloss: !S.gloss }); },
      closeGloss: function () { self.setState({ gloss: false }); },
      onTour: function () { S.tour ? self.setState({ tour: false }) : self.startTour(); },
      closeTour: function () { self.setState({ tour: false }); },
      next: function () { self.go(1); }, prev: function () { self.go(-1); },
      scenLow: function () { self.setScen('low'); }, scenBase: function () { self.setScen('base'); }, scenHigh: function () { self.setScen('high'); }
    };

    var MID = ['hero', 'ms', 'cap', 'cost', 'scale', 'op', 'roi', 'tco', 'vr', 'cash', 'evm', 'eac', 'par', 'pnl', 'launch', 'inv', 'roll', 'eff', 'sup', 'risk', 'reg', 'rel', 'rm'];
    V.mth = {}; V.mOn = {};
    MID.forEach(function (k) { V.mth[k] = function () { self.tog('math', k); }; V.mOn[k] = !!S.math[k]; });

    V.tourStep = S.step + 1; V.tourTotal = this.TOUR.length;
    var T = this.TOUR[S.step] || this.TOUR[0];
    V.tourTitle = T.t; V.tourNote = T.n;
    V.tourPct = ((S.step + 1) / this.TOUR.length * 100).toFixed(1) + '%';
    V.tourNotFirst = S.step > 0; V.tourNotLast = S.step < this.TOUR.length - 1; V.tourLast = S.step === this.TOUR.length - 1;

    if (!d) return V;

    var cg = d.capacity_gap, inv = d.unlaunched_inventory, sc = d.implied_scale_cost;
    var rate = S.rate, CEIL = cg.capacity_ceiling_per_day;
    V.rate = rate; V.rateTxt = rate.toFixed(2); V.ceil = CEIL.toFixed(1);
    V.rateMin = 0.5; V.rateMax = CEIL; V.rateStep = 0.01;
    V.onRate = function (e) { self.setState({ rate: Number(e.target.value), scen: 'custom' }); };
    V.dbtRate = cg.realized_peak_per_day.toFixed(2);
    V.avgRate = (inv.deployed_count / inv.elapsed_days).toFixed(2);
    V.scenLabel = S.scen === 'low' ? 'Programme-average realised pace' : S.scen === 'high' ? 'Stated factory ceiling' : S.scen === 'base' ? 'Best realised pace on record (dbt default)' : 'Your custom assumption';
    V.gen = this.dt(d.generated_at);

    var ms = (d.milestone_risk || []).map(function (m) {
      var proj = Math.round(m.checkpoint_count + m.days_remaining_at_checkpoint * rate);
      var short = Math.max(0, m.satellites_required - proj);
      var p = Math.min(100, proj / m.satellites_required * 100);
      return {
        key: m.milestone_date, date: self.dt(m.milestone_date), req: self.num(m.satellites_required), reqN: m.satellites_required,
        basis: m.regulatory_basis, cons: m.regulatory_consequence,
        cpDate: self.dt(m.checkpoint_date), cpCount: self.num(m.checkpoint_count), days: m.days_remaining_at_checkpoint,
        proj: self.num(proj), short: self.num(short), shortN: short, pct: self.pc(p), pw: p.toFixed(1) + '%',
        ok: short === 0, status: self.tc(m.status), color: short === 0 ? C.good : C.bad,
        waiver: !!m.waiver_requested,
        waiverTxt: m.waiver_requested ? (m.waiver_requested_extension_months + '-month extension requested ' + self.dt(m.waiver_requested_date)) : 'No waiver on file',
        hasCo: m.company_projected_count != null, co: self.num(m.company_projected_count), coShort: self.num(m.company_projected_shortfall),
        coW: Math.min(100, m.company_projected_count / m.satellites_required * 100).toFixed(1) + '%'
      };
    });
    V.ms = ms; V.msNear = ms[0] || {}; V.msLater = ms.slice(1);

    var startD = inv.production_start_date, EL = inv.elapsed_days;
    var HW = 1000, HH = 340, HL = 56, HR = 150, HT = 26, HB = 40;
    var maxY = EL * CEIL;
    var hx = function (t) { return HL + (HW - HL - HR) * (t / EL); };
    var hy = function (v) { return HT + (HH - HT - HB) * (1 - v / maxY); };
    var cps = (d.deployment_checkpoints || []).filter(function (c) { return c.cumulative_satellites != null && c.checkpoint_type !== 'company_projected'; })
      .map(function (c) { return { t: self.dd(startD, c.as_of_date), v: c.cumulative_satellites, date: c.as_of_date }; })
      .sort(function (a, b) { return a.t - b.t; });
    var lastV = cps.length ? cps[cps.length - 1].v : 0;
    var upEnd = EL * CEIL, loEnd = EL * rate;
    var actPts = cps.map(function (c) { return [hx(c.t), hy(c.v)]; });
    V.hero = {
      w: HW, h: HH, l: HL, t: HT, base: HH - HB, right: HW - HR,
      upD: 'M ' + hx(0).toFixed(1) + ' ' + hy(0).toFixed(1) + ' L ' + hx(EL).toFixed(1) + ' ' + hy(upEnd).toFixed(1),
      loD: 'M ' + hx(0).toFixed(1) + ' ' + hy(0).toFixed(1) + ' L ' + hx(EL).toFixed(1) + ' ' + hy(loEnd).toFixed(1),
      actD: actPts.length ? 'M ' + actPts.map(function (p) { return p[0].toFixed(1) + ' ' + p[1].toFixed(1); }).join(' L ') : '',
      gapD: actPts.length ? ('M ' + hx(0).toFixed(1) + ' ' + hy(0).toFixed(1) + ' L ' + hx(EL).toFixed(1) + ' ' + hy(upEnd).toFixed(1) + ' L ' + hx(EL).toFixed(1) + ' ' + hy(lastV).toFixed(1) + ' ' + actPts.slice().reverse().map(function (p) { return 'L ' + p[0].toFixed(1) + ' ' + p[1].toFixed(1); }).join(' ') + ' Z') : '',
      dots: cps.map(function (c, i) { return { key: 'hc' + i, x: hx(c.t), y: hy(c.v) }; }),
      reqY: hy(ms[0] ? ms[0].reqN : 1616), reqTxt: ms[0] ? ms[0].req : '',
      upY: hy(upEnd), loY: hy(loEnd), actY: hy(lastV),
      upTxt: this.num(Math.round(upEnd)), loTxt: this.num(Math.round(loEnd)), actTxt: this.num(lastV),
      startTxt: this.dt(startD), endTxt: this.dt(inv.latest_observed_date), days: this.num(EL),
      gapTxt: this.num(Math.round(upEnd) - lastV)
    };

    var util = rate / CEIL * 100;
    V.cap = {
      ceil: CEIL.toFixed(1), peak: cg.realized_peak_per_day.toFixed(2), gap: (CEIL - rate).toFixed(2),
      util: this.pc(util, 0), utilNum: util, dash: (util / 100 * 339.3).toFixed(1) + ' 999',
      cause: this.tc(cg.constraint_root_cause), note: cg.realized_peak_note, src: cg.source, url: cg.source_url,
      dbtUtil: this.pc(cg.utilization_pct * 100, 0), utilW: util.toFixed(1) + '%', color: util < 60 ? C.bad : util < 85 ? C.warn : C.good
    };

    var ce = d.cost_escalation || [];
    var cum = ce.filter(function (r) { return r.metric_type === 'cumulative_total_program'; });
    var yoy = ce.filter(function (r) { return r.metric_type !== 'cumulative_total_program'; });
    V.costRows = ce.map(function (r, i) {
      return {
        key: 'ce' + i, date: self.dt(r.as_of_date), type: self.tc(r.metric_type), cumulative: r.metric_type === 'cumulative_total_program', incremental: r.metric_type !== 'cumulative_total_program',
        lo: self.usd(r.low_estimate_usd), hi: self.usd(r.high_estimate_usd), same: r.low_estimate_usd === r.high_estimate_usd,
        range: r.low_estimate_usd === r.high_estimate_usd ? self.usd(r.low_estimate_usd) : (self.usd(r.low_estimate_usd) + '–' + self.usd(r.high_estimate_usd)),
        chg: r.pct_change_from_prior == null ? '—' : self.pc(r.pct_change_from_prior * 100, 0),
        srcType: self.tc(r.source_type), src: r.source, url: r.source_url
      };
    });
    V.cost = {
      first: cum[0] ? this.usd(cum[0].low_estimate_usd) : '—', firstDate: cum[0] ? this.dt(cum[0].as_of_date) : '—',
      last: cum.length ? this.usd(cum[cum.length - 1].low_estimate_usd) : '—', lastDate: cum.length ? this.dt(cum[cum.length - 1].as_of_date) : '—',
      growth: cum.length && cum[cum.length - 1].pct_change_from_prior != null ? this.pc(cum[cum.length - 1].pct_change_from_prior * 100, 0) : '—',
      yoy: yoy.length ? this.usd(yoy[0].low_estimate_usd) : '—', yoyDate: yoy.length ? this.dt(yoy[0].as_of_date) : '—',
      yoySrc: yoy.length ? yoy[0].source : '', yoyUrl: yoy.length ? yoy[0].source_url : '', hasYoy: yoy.length > 0
    };
    V.costBars = this.mkBars(cum.map(function (r) { return { label: String(r.as_of_date).slice(0, 4), vals: { v: r.low_estimate_usd } }; }),
      [{ key: 'v', label: 'Cumulative programme estimate', color: C.acc }], { w: 700, h: 200, bw: 64, fmt: function (v) { return self.usd(v); } });

    V.scale = {
      lo: this.usd(sc.implied_scale_cost_low_usd), hi: this.usd(sc.implied_scale_cost_high_usd),
      uLo: this.usd(sc.unit_cost_low_usd), uHi: this.usd(sc.unit_cost_high_usd),
      target: this.num(sc.constellation_target), note: sc.calculation_note, src: sc.source, url: sc.source_url, date: this.dt(sc.as_of_date)
    };

    var plan = d.op1_op2_plan || [];
    V.planRows = plan.map(function (p, i) {
      return { key: 'p' + i, fy: p.fiscal_year, opex: self.usd(p.opex_usd), capex: self.usd(p.capex_usd), hc: self.num(p.headcount), chg: p.capex_yoy_change_usd == null ? 'baseline' : self.usd(p.capex_yoy_change_usd), down: p.capex_yoy_change_usd < 0 };
    });
    V.planBars = this.mkBars(plan.map(function (p) { return { label: String(p.fiscal_year), vals: { o: p.opex_usd, c: p.capex_usd } }; }),
      [{ key: 'o', label: 'OpEx', color: C.acc2 }, { key: 'c', label: 'CapEx', color: C.accD }], { w: 700, h: 220, bw: 24, fmt: function (v) { return self.usd(v); } });
    V.hcLine = this.mkLines(plan.map(function (p) { return String(p.fiscal_year); }),
      [{ key: 'hc', label: 'Headcount', color: C.acc, vals: plan.map(function (p) { return p.headcount; }), area: true }], { w: 700, h: 180, fmt: function (v) { return self.num(Math.round(v)); } });
    V.planPlain = plan.length ? ('CapEx is front-loaded — ' + this.usd(plan[0].capex_usd) + ' in ' + plan[0].fiscal_year + ', falling to ' + this.usd(plan[plan.length - 1].capex_usd) + ' by ' + plan[plan.length - 1].fiscal_year + ' — while OpEx and headcount keep climbing. That is the normal shape for a build-then-operate programme: you stop buying factories and start paying to run them.') : '';

    var roiMax = Math.max.apply(null, (d.roi_payback_scenarios || []).map(function (r) { return r.roi_pct; }).concat([1]));
    V.roi = (d.roi_payback_scenarios || []).map(function (r, i) {
      return { key: 'r' + i, name: r.scenario_name, capex: self.usd(r.capex_usd), ben: self.usd(r.annual_benefit_usd), pb: r.payback_years.toFixed(1), roi: self.pc(r.roi_pct, 0), w: (r.roi_pct / roiMax * 100).toFixed(1) + '%', color: r.roi_pct >= 40 ? C.good : r.roi_pct >= 25 ? C.warn : C.bad, notes: r.notes };
    });

    var mvb = d.makevsbuy || [], cats = [];
    mvb.forEach(function (r) {
      var g = cats.filter(function (c) { return c.label === r.category_label; })[0];
      if (!g) { g = { label: r.category_label, rows: [] }; cats.push(g); }
      g.rows.push(r);
    });
    V.tco = cats.map(function (g, i) {
      var vals = g.rows.map(function (r) { return r.annual_tco_usd; });
      var mn = Math.min.apply(null, vals), mx = Math.max.apply(null, vals);
      return {
        key: 't' + i, label: g.label,
        rows: g.rows.map(function (r, j) {
          return { key: 'tr' + i + j, opt: r.option_label, unit: self.usd(r.unit_cost_usd), vol: self.num(r.annual_volume), tco: self.usd(r.annual_tco_usd), delta: r.tco_delta_vs_cheaper_option_usd ? ('+' + self.usd(r.tco_delta_vs_cheaper_option_usd)) : 'lower TCO', win: r.annual_tco_usd === mn, w: (r.annual_tco_usd / mx * 100).toFixed(1) + '%', color: r.annual_tco_usd === mn ? C.good : C.mut };
        })
      };
    });

    var vd = d.variance_demo || [];
    V.varRows = vd.map(function (v, i) {
      return { key: 'v' + i, cc: v.cost_center, per: v.period, bud: self.usd(v.budget_amount), act: self.usd(v.actual_amount), tot: self.usd(v.total_variance, true), pct: self.pc(v.total_variance / v.budget_amount * 100), price: self.usd(v.price_driver, true), vol: self.usd(v.volume_driver, true), scope: self.usd(v.scope_driver, true), tim: self.usd(v.timing_driver, true), tie: v.sum_of_drivers === v.total_variance, color: v.total_variance > 0 ? C.bad : C.good };
    });
    V.varBars = this.mkBars(vd.map(function (v) { return { label: v.period, vals: { b: v.budget_amount, a: v.actual_amount } }; }),
      [{ key: 'b', label: 'Budget', color: C.accD }, { key: 'a', label: 'Actual', color: C.acc }], { w: 660, h: 210, bw: 30, fmt: function (v) { return self.usd(v); } });
    V.varStack = this.mkStack(vd.map(function (v) { return { label: v.period, vals: { p: v.price_driver, vo: v.volume_driver, s: v.scope_driver, t: v.timing_driver } }; }),
      [{ key: 'p', label: 'Price', color: C.acc }, { key: 'vo', label: 'Volume', color: C.acc2 }, { key: 's', label: 'Scope', color: C.accD }, { key: 't', label: 'Timing', color: C.warn }], { w: 660, h: 210, bw: 46, fmt: function (v) { return self.usd(v); } });
    V.varTie = vd.length > 0 && vd.every(function (v) { return v.sum_of_drivers === v.total_variance; });
    V.varN = vd.length;

    var cb = d.cashflow_breakdown || [], gm = [];
    cb.forEach(function (r) {
      var g = gm.filter(function (x) { return x.cat === r.category; })[0];
      if (!g) { g = { cat: r.category, type: r.cost_type, ord: r.category_order, plan: 0, act: 0, rows: [] }; gm.push(g); }
      g.plan += r.plan_amount_usd; g.act += r.actual_amount_usd; g.rows.push(r);
    });
    gm.sort(function (a, b) { return a.ord - b.ord; });
    var gmMax = Math.max.apply(null, gm.map(function (g) { return g.act; }).concat([1]));
    V.cfGroups = gm.map(function (g, i) {
      var key = 'cf' + i, v = g.act - g.plan;
      return {
        key: key, cat: g.cat, type: self.tc(g.type), dir: g.type === 'direct',
        plan: self.usd(g.plan), act: self.usd(g.act), varr: self.usd(v, true), pct: self.pc(v / g.plan * 100),
        color: v > 0 ? C.bad : C.good, open: !!S.acc[key], closed: !S.acc[key],
        on: function () { self.tog('acc', key); },
        w: (g.act / gmMax * 100).toFixed(1) + '%', n: g.rows.length,
        rows: g.rows.map(function (r, j) {
          return { key: key + '-' + j, sub: r.subcategory, plan: self.usd(r.plan_amount_usd), act: self.usd(r.actual_amount_usd), varr: self.usd(r.variance_usd, true), pct: self.pc(r.variance_pct), comp: self.pc(r.percent_complete * 100, 0), ev: self.usd(r.ev_usd), cpi: r.cpi.toFixed(3), spi: r.spi.toFixed(3), cpiC: r.cpi < 1 ? C.bad : C.good, spiC: r.spi < 1 ? C.bad : C.good, color: r.variance_usd > 0 ? C.bad : C.good };
        })
      };
    });
    var sum = function (a, k) { return a.reduce(function (s, r) { return s + r[k]; }, 0); };
    var dirT = cb.filter(function (r) { return r.cost_type === 'direct'; });
    var indT = cb.filter(function (r) { return r.cost_type !== 'direct'; });
    V.cf = {
      nSub: cb.length, nCat: gm.length, period: cb.length ? cb[0].period : '',
      dirPlan: this.usd(sum(dirT, 'plan_amount_usd')), dirAct: this.usd(sum(dirT, 'actual_amount_usd')),
      indPlan: this.usd(sum(indT, 'plan_amount_usd')), indAct: this.usd(sum(indT, 'actual_amount_usd')),
      totPlan: this.usd(sum(cb, 'plan_amount_usd')), totAct: this.usd(sum(cb, 'actual_amount_usd')),
      totVar: this.usd(sum(cb, 'actual_amount_usd') - sum(cb, 'plan_amount_usd'), true),
      totPct: this.pc((sum(cb, 'actual_amount_usd') / sum(cb, 'plan_amount_usd') - 1) * 100)
    };
    var ct = d.cashflow_trend || [];
    V.cfLine = this.mkLines(ct.map(function (r) { return r.period; }), [
      { key: 'p', label: 'Plan', color: C.mut, vals: ct.map(function (r) { return r.plan_amount_usd; }) },
      { key: 'f', label: 'Forecast', color: C.warn, vals: ct.map(function (r) { return r.forecast_amount_usd; }), dash: '5 4' },
      { key: 'a', label: 'Actual', color: C.acc, vals: ct.map(function (r) { return r.is_forecast ? null : r.actual_amount_usd; }), width: 2.8 }
    ], { w: 700, h: 220, fmt: function (v) { return self.usd(v); } });
    V.cfTrend = ct.map(function (r, i) { return { key: 'ct' + i, per: r.period, plan: self.usd(r.plan_amount_usd), act: r.is_forecast ? '—' : self.usd(r.actual_amount_usd), fc: self.usd(r.forecast_amount_usd), isF: r.is_forecast, real: !r.is_forecast }; });

    var e = d.evm_rollup;
    V.evm = {
      bac: this.usd(e.bac), ac: this.usd(e.ac), ev: this.usd(e.ev), cv: this.usd(e.cv, true), sv: this.usd(e.sv, true),
      cpi: e.cpi.toFixed(4), spi: e.spi.toFixed(4), cpiShort: e.cpi.toFixed(3), spiShort: e.spi.toFixed(3),
      cpiGap: this.pc((1 - e.cpi) * 100), spiGap: this.pc((1 - e.spi) * 100),
      eacT: this.usd(e.eac_typical), eacC: this.usd(e.eac_cpi), eacX: this.usd(e.eac_composite), vac: this.usd(e.vac, true),
      tcpiB: e.tcpi_to_bac.toFixed(4), tcpiE: e.tcpi_to_eac.toFixed(4), over: !!e.ac_exceeds_bac,
      cpiC: e.cpi < 1 ? C.bad : C.good, spiC: e.spi < 1 ? C.bad : C.good,
      cpiW: (Math.min(1, e.cpi) * 100).toFixed(1) + '%', spiW: (Math.min(1, e.spi) * 100).toFixed(1) + '%',
      acW: '100%', evW: (e.ev / e.ac * 100).toFixed(1) + '%', bacW: (e.bac / e.ac * 100).toFixed(1) + '%',
      notes: e.notes
    };

    var es = d.eac_sensitivity || [];
    var eMax = Math.max.apply(null, es.map(function (r) { return Math.abs(r.delta_from_base_usd); }).concat([1]));
    V.eac = {
      base: es.length ? this.usd(es[0].eac_composite_base_usd) : '—',
      rows: es.map(function (r, i) {
        var sp = Number(r.swing_pct);
        return { key: 'ea' + i, driver: r.driver, swing: (sp > 0 ? '+' : '') + (sp * 100).toFixed(0) + '%', val: r.swung_value.toFixed(4), eac: self.usd(r.eac_composite_usd), delta: self.usd(r.delta_from_base_usd, true), w: (Math.abs(r.delta_from_base_usd) / eMax * 44).toFixed(1) + '%', pos: r.delta_from_base_usd > 0, neg: r.delta_from_base_usd <= 0, color: r.delta_from_base_usd > 0 ? C.bad : C.good };
      })
    };

    var par = cb.filter(function (r) { return r.variance_usd > 0; }).sort(function (a, b) { return b.variance_usd - a.variance_usd; });
    var pTot = par.reduce(function (s, r) { return s + r.variance_usd; }, 0) || 1;
    var run = 0;
    V.par = par.map(function (r, i) {
      run += r.variance_usd;
      return { key: 'pa' + i, i: i + 1, sub: r.subcategory, cat: r.category, v: self.usd(r.variance_usd, true), share: self.pc(r.variance_usd / pTot * 100), cum: self.pc(run / pTot * 100), w: (r.variance_usd / par[0].variance_usd * 100).toFixed(1) + '%', vital: run / pTot <= 0.8, color: run / pTot <= 0.8 ? C.bad : C.mut };
    });
    V.parTot = this.usd(pTot, true); V.parVital = V.par.filter(function (r) { return r.vital; }).length; V.parAll = par.length;

    var p = d.pnl_waterfall;
    var steps = [{ l: 'Revenue', v: p.revenue_usd, t: 'x' }, { l: 'Direct COGS', v: -p.direct_cogs_usd, t: 'x' }, { l: 'Gross margin', v: p.gross_margin_usd, t: 'tot' }, { l: 'Indirect OpEx', v: -p.indirect_opex_usd, t: 'x' }, { l: 'Operating margin', v: p.operating_margin_usd, t: 'tot' }];
    var WW = 700, WH = 260, WL = 60, WR = 12, WT = 26, WB = 44;
    var acc2 = 0, wv = [];
    steps.forEach(function (s) {
      if (s.t === 'tot') { wv.push({ l: s.l, v: s.v, from: 0, to: s.v, tot: true }); acc2 = s.v; }
      else { wv.push({ l: s.l, v: s.v, from: acc2, to: acc2 + s.v, tot: false }); acc2 += s.v; }
    });
    var wlo = Math.min.apply(null, wv.map(function (w) { return Math.min(w.from, w.to); }).concat([0]));
    var whi = Math.max.apply(null, wv.map(function (w) { return Math.max(w.from, w.to); }).concat([0]));
    var wy = function (v) { return WT + (WH - WT - WB) * (1 - (v - wlo) / ((whi - wlo) || 1)); };
    var bwd = (WW - WL - WR) / steps.length;
    var wt = [];
    for (var wi = 0; wi <= 4; wi++) { var wvv = wlo + (whi - wlo) * wi / 4; wt.push({ key: 'wt' + wi, y: wy(wvv), label: this.usd(wvv) }); }
    V.pnl = {
      w: WW, h: WH, ml: WL, x2: WW - WR, zero: wy(0), ticks: wt,
      bars: wv.map(function (s, i) {
        var y0 = wy(s.from), y1 = wy(s.to);
        return { key: 'w' + i, x: WL + bwd * i + bwd * 0.2, w: bwd * 0.6, y: Math.min(y0, y1), h: Math.max(2, Math.abs(y1 - y0)), fill: s.tot ? C.acc : (s.v > 0 ? C.good : C.bad), label: s.l, val: self.usd(s.v, !s.tot), lx: WL + bwd * i + bwd / 2, ly: Math.min(y0, y1) - 9, bx: WH - WB + 18 };
      }),
      period: p.period, rev: this.usd(p.revenue_usd), cogs: this.usd(p.direct_cogs_usd), opex: this.usd(p.indirect_opex_usd),
      gm: this.usd(p.gross_margin_usd, true), om: this.usd(p.operating_margin_usd, true), notes: p.notes
    };

    var lv = d.launch_vehicle_reliability || [];
    V.lvStack = this.mkStack(lv.map(function (r) { return { label: r.launch_vehicle, vals: { s: r.success_events - (r.success_with_incident_events || 0), si: r.success_with_incident_events || 0, dl: r.delay_events, f: r.failure_events } }; }),
      [{ key: 's', label: 'Clean success', color: C.good }, { key: 'si', label: 'Success with incident', color: C.warn }, { key: 'dl', label: 'Delay', color: C.acc2 }, { key: 'f', label: 'Failure', color: C.bad }],
      { w: 620, h: 200, bw: 60, fmt: function (v) { return self.num(Math.round(v)); } });
    V.lv = lv.map(function (r, i) {
      return { key: 'lv' + i, name: r.launch_vehicle, tot: r.total_events, evLabel: r.total_events === 1 ? '1 event' : r.total_events + ' events', s: r.success_events, si: r.success_with_incident_events, dl: r.delay_events, f: r.failure_events, adverse: self.pc((r.delay_events + r.failure_events) / Math.max(1, r.total_events) * 100, 0), disrupted: (r.delay_events + r.failure_events) > 0 };
    });
    V.lvTot = lv.reduce(function (s, r) { return s + r.total_events; }, 0);
    V.lvFam = lv.length;
    V.lvDisrupted = lv.filter(function (r) { return (r.delay_events + r.failure_events) > 0; }).length;
    V.timeline = (d.launch_disruption_timeline || []).map(function (t, i) {
      var exact = !!t.has_exact_date && !!t.event_date;
      var conf = String(t.date_confidence || '').toLowerCase();
      return {
        key: 'tl' + i, exact: exact, undated: !exact,
        date: exact ? self.dt(t.event_date) : (conf === 'approximate' ? 'Date approximate' : 'Date not disclosed'),
        vehicle: t.launch_vehicle, type: self.tc(t.event_type),
        conf: conf === 'approximate' ? 'no exact date in public reporting' : 'date not disclosed — excluded from the reliability trend',
        desc: t.description, src: t.source, url: t.source_url, color: self.tier(t.event_type)
      };
    });

    var pUp = Math.round(EL * CEIL), pLo = Math.round(EL * rate);
    V.inv = {
      start: this.dt(inv.production_start_date), latest: this.dt(inv.latest_observed_date), days: this.num(EL),
      dep: this.num(inv.deployed_count), upProd: this.num(pUp), loProd: this.num(pLo),
      upBack: this.num(Math.max(0, pUp - inv.deployed_count)), loBack: this.num(Math.max(0, pLo - inv.deployed_count)),
      upRate: CEIL.toFixed(1), loRate: rate.toFixed(2), note: inv.calculation_note,
      loW: (pLo / pUp * 100).toFixed(1) + '%', depW: (inv.deployed_count / pUp * 100).toFixed(1) + '%'
    };

    var oe = d.operational_efficiency_trend || [], oeBy = {};
    oe.forEach(function (r) { oeBy[r.as_of_date] = r; });
    var rf = d.capitalized_inventory_rollforward || [];
    var uLo = sc.unit_cost_low_usd, uHi = sc.unit_cost_high_usd, bl0 = null, bh0 = null;
    V.roll = rf.map(function (r, i) {
      var o = oeBy[r.as_of_date] || {};
      var els = o.elapsed_days_since_start != null ? o.elapsed_days_since_start : self.dd(startD, r.as_of_date);
      var dep = o.actual_cumulative_deployed != null ? o.actual_cumulative_deployed : 0;
      var bLo = Math.max(0, Math.round(els * rate) - dep), bHi = Math.max(0, Math.round(els * CEIL) - dep);
      var vLo = bLo * uLo, vHi = bHi * uHi;
      var row = {
        key: 'rf' + i, date: self.dt(r.as_of_date), bLo: self.num(bLo), bHi: self.num(bHi),
        vLo: self.usd(vLo), vHi: self.usd(vHi),
        beginLo: bl0 == null ? 'opening' : self.usd(bl0), beginHi: bh0 == null ? 'opening' : self.usd(bh0),
        chgLo: bl0 == null ? '—' : self.usd(vLo - bl0, true), chgHi: bh0 == null ? '—' : self.usd(vHi - bh0, true),
        first: bl0 == null, notFirst: bl0 != null, note: r.calculation_note
      };
      bl0 = vLo; bh0 = vHi; return row;
    });
    V.rollLast = V.roll.length ? V.roll[V.roll.length - 1] : {};
    V.unitLo = this.usd(uLo); V.unitHi = this.usd(uHi);

    V.effLine = this.mkLines(oe.map(function (r) { return self.md(r.as_of_date); }), [
      { key: 'u', label: 'Modelled built @ ceiling', color: C.accD, vals: oe.map(function (r) { return Math.round(r.elapsed_days_since_start * CEIL); }) },
      { key: 'l', label: 'Modelled built @ assumption', color: C.warn, vals: oe.map(function (r) { return Math.round(r.elapsed_days_since_start * rate); }), dash: '5 4' },
      { key: 'a', label: 'Actually deployed', color: C.acc, vals: oe.map(function (r) { return r.actual_cumulative_deployed; }), width: 2.8 }
    ], { w: 700, h: 230, fmt: function (v) { return self.num(Math.round(v)); } });
    V.utilLine = this.mkLines(oe.map(function (r) { return self.md(r.as_of_date); }),
      [{ key: 'u', label: 'Interval launch utilisation', color: C.acc, vals: oe.map(function (r) { return r.interval_utilization_pct; }), area: true }],
      { w: 700, h: 190, min: 0, max: 100, fmt: function (v) { return Math.round(v) + '%'; } });
    V.eff = oe.map(function (r, i) {
      return { key: 'oe' + i, date: self.dt(r.as_of_date), dep: self.num(r.actual_cumulative_deployed), days: self.num(r.elapsed_days_since_start), iRate: r.interval_realized_rate_per_day.toFixed(3), iUtil: self.pc(r.interval_utilization_pct), iDays: r.interval_days, iSats: self.num(r.interval_satellites), color: r.interval_utilization_pct < 50 ? C.bad : r.interval_utilization_pct < 80 ? C.warn : C.good, w: Math.min(100, r.interval_utilization_pct).toFixed(1) + '%' };
    });
    V.effN = oe.length;

    V.sup = (d.supplier_concentration || []).map(function (r, i) {
      var dots = [];
      for (var j = 0; j < Math.max(1, r.illustrative_supplier_count); j++) dots.push({ key: 'sd' + i + j });
      return { key: 'sp' + i, name: r.component_name, real: !!r.is_real_bottleneck, n: r.illustrative_supplier_count, tier: self.tc(r.risk_tier), color: self.tier(r.risk_tier), notes: r.notes, src: r.source, url: r.source_url, hasSrc: !!r.source_url, noSrc: !r.source_url, dots: dots };
    });
    V.supHigh = (d.supplier_concentration || []).filter(function (r) { return /high/.test(String(r.risk_tier)); }).length;

    V.safety = (d.safety_incidents || []).map(function (r, i) {
      return { key: 'sf' + i, date: self.dt(r.incident_date), desc: r.description, party: r.disputing_party, src: r.source, url: r.source_url };
    });
    V.safetyN = V.safety.length;

    var dp = d.d2d_pipeline;
    V.d2d = {
      name: dp.milestone_name, date: this.dt(dp.filing_date), sats: this.num(dp.satellites_requested),
      fw: dp.review_framework, tx: dp.related_transaction, yr: dp.related_transaction_close_year,
      src: dp.source, url: dp.source_url, txSrc: dp.related_transaction_source, txUrl: dp.related_transaction_source_url,
      core: this.num(sc.constellation_target), ratio: (dp.satellites_requested / sc.constellation_target).toFixed(2),
      coreW: (sc.constellation_target / dp.satellites_requested * 100).toFixed(1) + '%'
    };

    var wf = d.workforce_signal;
    V.wf = { n: this.num(wf.open_positions_redmond), date: this.dt(wf.as_of_date), sig: this.tc(wf.signal), src: wf.source, url: wf.source_url };

    var kp = d.operational_kpi_framework || [];
    var doms = ['All'].concat(kp.map(function (r) { return r.domain; }).filter(function (v, i, a) { return a.indexOf(v) === i; }));
    var stats = ['All'].concat(kp.map(function (r) { return r.status; }).filter(function (v, i, a) { return a.indexOf(v) === i; }));
    var kf = kp.filter(function (r) { return (S.kpiDom === 'All' || r.domain === S.kpiDom) && (S.kpiStat === 'All' || r.status === S.kpiStat); });
    var so = S.kpiSort;
    kf = kf.slice().sort(function (a, b) {
      if (so === 'name') return a.kpi_name.localeCompare(b.kpi_name);
      if (so === 'status') return String(a.status).localeCompare(String(b.status)) || a.domain.localeCompare(b.domain);
      return (a.domain_order - b.domain_order) || a.kpi_name.localeCompare(b.kpi_name);
    });
    V.kpiDoms = doms.map(function (x) { return { key: 'kd' + x, label: x, sel: S.kpiDom === x, on: function () { self.setState({ kpiDom: x }); } }; });
    var slab = function (s) { return s === 'below' ? 'Below target' : s === 'no_data' ? 'No public data' : self.tc(s); };
    V.kpiStats = stats.map(function (x) { return { key: 'ks' + x, label: slab(x), sel: S.kpiStat === x, on: function () { self.setState({ kpiStat: x }); } }; });
    V.kpiRows = kf.map(function (r, i) {
      return { key: 'k' + i, dom: r.domain, name: r.kpi_name, def: r.definition, target: r.target_benchmark, freq: r.frequency, obj: r.strategic_objective, actual: r.actual_signal || 'no public data', has: !!r.actual_signal, none: !r.actual_signal, status: slab(r.status), color: self.tier(r.status) };
    });
    V.kpiN = kf.length; V.kpiAll = kp.length; V.kpiDomN = doms.length - 1;
    V.kpiFail = kp.filter(function (r) { return /fail|breach|miss|below/.test(String(r.status)); }).length;
    V.kpiNoData = kp.filter(function (r) { return r.status === 'no_data'; }).length;
    V.kpiSortDom = function () { self.setState({ kpiSort: 'domain' }); };
    V.kpiSortName = function () { self.setState({ kpiSort: 'name' }); };
    V.kpiSortStat = function () { self.setState({ kpiSort: 'status' }); };
    V.kpiSort = { domain: so === 'domain', name: so === 'name', status: so === 'status' };
    V.kpiFiltered = S.kpiDom !== 'All' || S.kpiStat !== 'All';
    V.kpiReset = function () { self.setState({ kpiDom: 'All', kpiStat: 'All' }); };

    var ri = d.program_risk_index;
    var sig = [
      { l: 'Milestone', p: ri.milestone_signal_pct, a: ri.milestone_attribution_pct, w: 30 },
      { l: 'Launch', p: ri.launch_signal_pct, a: ri.launch_attribution_pct, w: 25 },
      { l: 'Cost', p: ri.cost_signal_pct, a: ri.cost_attribution_pct, w: 20 },
      { l: 'Supplier', p: ri.supplier_signal_pct, a: ri.supplier_attribution_pct, w: 15 },
      { l: 'Safety', p: ri.safety_signal_pct, a: ri.safety_attribution_pct, w: 10 }
    ];
    var aMax = Math.max.apply(null, sig.map(function (s) { return s.a; }).concat([1]));
    V.ri = {
      score: ri.composite_score_pct.toFixed(1), tier: this.tc(ri.risk_tier), color: this.tier(ri.risk_tier),
      dash: (ri.composite_score_pct / 100 * 339.3).toFixed(1) + ' 999', notes: ri.notes,
      sig: sig.map(function (s, i) {
        return { key: 'rs' + i, l: s.l, p: self.pc(s.p, 0), pw: s.p.toFixed(1) + '%', a: self.pc(s.a), aw: (s.a / aMax * 100).toFixed(1) + '%', w: s.w + '%', color: self.tier(s.p >= 70 ? 'high' : s.p >= 40 ? 'medium' : 'low') };
      })
    };

    var order = { high: 3, medium: 2, low: 1 };
    var rr = (d.risk_register || []).slice();
    rr.sort(function (a, b) {
      if (S.rrSort === 'prob') return b.probability_pct - a.probability_pct;
      if (S.rrSort === 'cat') return String(a.category).localeCompare(String(b.category));
      return ((order[b.exposure_tier] || 0) - (order[a.exposure_tier] || 0)) || (b.probability_pct - a.probability_pct);
    });
    V.rr = rr.map(function (r, i) {
      return { key: 'rr' + i, id: r.risk_id, name: self.tc(r.risk_name), cat: self.tc(r.category), desc: r.description, prob: self.pc(r.probability_pct, 0), probW: Math.min(100, r.probability_pct).toFixed(0) + '%', pt: self.tc(r.probability_tier), it: r.impact_tier ? self.tc(r.impact_tier) : 'monitored only', et: r.exposure_tier ? self.tc(r.exposure_tier) : '—', color: self.tier(r.exposure_tier || r.probability_tier), inC: !!r.in_composite_index, mon: !r.in_composite_index, status: self.tc(r.status), mart: r.source_mart };
    });
    V.rrSort = { exposure: S.rrSort === 'exposure', prob: S.rrSort === 'prob', cat: S.rrSort === 'cat' };
    V.rrSortE = function () { self.setState({ rrSort: 'exposure' }); };
    V.rrSortP = function () { self.setState({ rrSort: 'prob' }); };
    V.rrSortC = function () { self.setState({ rrSort: 'cat' }); };
    V.rrScored = rr.filter(function (r) { return r.in_composite_index; }).length;
    V.rrMon = rr.length - V.rrScored;

    var lt = d.launch_reliability_trend || [];
    V.rel = lt.map(function (r, i) {
      return { key: 'lr' + i, date: self.dt(r.event_date), v: r.launch_vehicle, t: self.tc(r.event_type), rate: self.pc(r.running_adverse_event_rate_pct, 0), tot: r.running_total_events, src: r.source, url: r.source_url };
    });
    V.relNote = lt.length ? lt[0].calculation_note : '';
    V.relLine = this.mkLines(lt.map(function (r) { return self.md(r.event_date); }),
      [{ key: 'r', label: 'Cumulative adverse-event rate', color: C.acc, vals: lt.map(function (r) { return r.running_adverse_event_rate_pct; }), area: true }],
      { w: 620, h: 180, min: 0, max: 100, fmt: function (v) { return Math.round(v) + '%'; } });
    V.relN = lt.length;

    var rm = d.roadmap_90day || [];
    var maxDay = Math.max.apply(null, rm.map(function (r) { return r.phase_end_day; }).concat([90]));
    V.rm = rm.map(function (r, i) {
      return {
        key: 'rm' + i, id: r.roadmap_id, risk: self.tc(r.risk_name), dom: r.domain, role: r.accountable_role,
        action: r.action, target: r.target_description, rationale: r.rationale_note, hasRat: !!r.rationale_note,
        et: self.tc(r.exposure_tier), color: self.tier(r.exposure_tier), crit: r.exposure_tier === 'high',
        left: ((r.phase_start_day - 1) / maxDay * 100).toFixed(1) + '%', w: ((r.phase_end_day - r.phase_start_day + 1) / maxDay * 100).toFixed(1) + '%',
        span: 'Day ' + r.phase_start_day + '–' + r.phase_end_day,
        tasks: String(r.finance_manager_tasks || '').split('|').map(function (t, j) { return { key: 'ft' + i + j, t: t.trim() }; }),
        deliv: r.finance_deliverable
      };
    });
    V.rmN = rm.length;
    V.rmDoms = rm.map(function (r) { return r.domain; }).filter(function (v, i, a) { return a.indexOf(v) === i; }).length;
    V.rmCrit = rm.filter(function (r) { return r.exposure_tier === 'high'; }).length;
    V.rmCritRows = V.rm.filter(function (r) { return r.crit; });
    V.rmRest = V.rm.filter(function (r) { return !r.crit; });

    V.dqr = (d.data_quality_routing || []).map(function (r, i) { return { key: 'dq' + i, cat: self.tc(r.category), desc: r.description, to: r.routes_to, auth: r.authority_note }; });
    V.dqi = (d.data_quality_incidents || []).map(function (r, i) { return { key: 'di' + i, date: self.dt(r.incident_date), cat: self.tc(r.category), title: r.title, cause: r.root_cause, det: r.detection_method, safe: r.regression_safeguard, sha: String(r.commit_sha).slice(0, 7), url: r.commit_url }; });

    V.exec = [
      { k: 'ex1', kicker: 'Regulatory', v: V.msNear.short, unit: 'satellites short', l: 'of the ' + V.msNear.date + ' FCC licence condition, projected at ' + rate.toFixed(2) + '/day', color: C.bad, to: 's-milestone' },
      { k: 'ex2', kicker: 'Constraint', v: this.pc(util, 0), unit: 'of factory capacity', l: 'actually reaching orbit — the bottleneck is launch supply, not manufacturing', color: C.warn, to: 's-capacity' },
      { k: 'ex3', kicker: 'Cost', v: V.cost.growth, unit: 'programme cost growth', l: 'in the stated total since ' + V.cost.firstDate + ', on top of a separate single-year headwind', color: C.bad, to: 's-cost' },
      { k: 'ex4', kicker: 'Inventory', v: V.inv.loBack + '–' + V.inv.upBack, unit: 'satellites on the ground', l: 'modelled as built but unlaunched — a carrying value of ' + V.rollLast.vLo + '–' + V.rollLast.vHi, color: C.acc, to: 's-inv' }
    ].map(function (x) { return { key: x.k, kicker: x.kicker, v: x.v, unit: x.unit, l: x.l, color: x.color, on: function () { self.jump(x.to); } }; });

    V.through = 'At ' + rate.toFixed(2) + ' satellites a day this programme reaches ' + V.msNear.proj + ' of the ' + V.msNear.req + ' the FCC requires by ' + V.msNear.date + ' — ' + V.msNear.short + ' short. It is not short because the factory cannot build them: at the stated ceiling of ' + CEIL.toFixed(1) + '/day the line would have produced ' + V.inv.upProd + ' by ' + V.inv.latest + ', against ' + V.inv.dep + ' actually in orbit. The constraint is launch. So the money question is not whether we can build faster — it is what ' + V.rollLast.vLo + '–' + V.rollLast.vHi + ' of finished hardware sitting on the ground costs to carry, and what a fourth launch provider is worth measured against that.';
    V.recSummary = 'Three facts, all from the analysis above: the near-term milestone is projected to fall ' + V.msNear.short + ' satellites short; the stated programme cost has risen ' + V.cost.growth + ' since ' + V.cost.firstDate + '; and the composite delivery-risk index sits at ' + V.ri.score + '% — ' + V.ri.tier.toLowerCase() + '. Here is what I would put on the table.';

    var topSig = sig.slice().sort(function (a, b) { return b.a - a.a; })[0];
    var topRisk = rr.filter(function (r) { return r.in_composite_index; })[0];
    V.riskBullet = 'Watch the ' + (topSig ? topSig.l.toLowerCase() : 'milestone') + ' signal first. It contributes the largest share of the ' + V.ri.score + '% composite index at ' + this.pc(topSig ? topSig.a : 0) + ' of the total, and the register\u2019s highest-exposure row right now is ' + (topRisk ? this.tc(topRisk.risk_name).toLowerCase() : 'cost escalation') + '. If only one thing gets a weekly finance review, it is that one \u2014 chosen by the data, not by preference.';

    var PD = {
      ms: { label: 'Milestone shortfall', value: V.msNear.short, sub: 'satellites · ' + V.msNear.date },
      cap: { label: 'Launch utilisation', value: this.pc(util, 0), sub: 'of factory ceiling' },
      cost: { label: 'Programme cost', value: V.cost.last, sub: 'stated ' + V.cost.lastDate },
      scale: { label: 'Implied hardware bill', value: V.scale.lo + '–' + V.scale.hi, sub: 'at full constellation' },
      inv: { label: 'Unlaunched inventory', value: V.inv.loBack + '–' + V.inv.upBack, sub: 'satellites, modelled' },
      roll: { label: 'Carrying value', value: V.rollLast.vLo + '–' + V.rollLast.vHi, sub: 'modelled, ' + V.rollLast.date },
      evm: { label: 'CPI / SPI', value: V.evm.cpiShort + ' / ' + V.evm.spiShort, sub: 'both below 1.0' },
      eac: { label: 'EAC composite', value: V.evm.eacX, sub: 'vs BAC ' + V.evm.bac },
      risk: { label: 'Delivery risk index', value: V.ri.score + '%', sub: V.ri.tier },
      d2d: { label: 'D2D filing', value: V.d2d.sats, sub: 'satellites requested' }
    };
    V.pinOn = {}; V.pinOff = {}; V.pinAdd = {};
    Object.keys(PD).forEach(function (k) {
      V.pinOn[k] = S.pins.indexOf(k) >= 0;
      V.pinOff[k] = !V.pinOn[k];
      V.pinAdd[k] = function () { self.togPin(k); };
    });
    V.pinned = S.pins.filter(function (k) { return PD[k]; }).map(function (k) {
      return { key: 'pin' + k, label: PD[k].label, value: PD[k].value, sub: PD[k].sub, on: function () { self.togPin(k); } };
    });
    V.pinN = V.pinned.length; V.hasPins = V.pinN > 0; V.noPins = V.pinN === 0;
    V.clearPins = function () { self.setState({ pins: [] }); };

    return V;
  }
}
