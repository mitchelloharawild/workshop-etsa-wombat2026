// Slider for the length of a loop of monthly data, drawn like coord_loop():
//
//   <div class="webr-slider loop-slider"><script type="application/json">
//     {"month": [...], "y": [...], "ylab": "...", "value": 5, "max": 36}
//
// `month` is the number of months since January 1970, so that loops of whole
// years start in January. Made by loop_slider() in R/loop-slider.R.
(function () {
  var INK = "#4D4D4D", PANEL = "#EBEBEB";
  var WIDTH = 1256, HEIGHT = 440;
  var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  // Lines of each loop, with the connections between loops split at the edges
  function loops(month, y, length) {
    var out = [], key = null;
    month.forEach(function (m, i) {
      var k = Math.floor(m / length), x = m - k * length;
      if (key !== null && k !== key) {
        // A step of one month always crosses exactly at the loop's end
        out.push({ k: key, x: length, y: y[i] });
      }
      key = k;
      out.push({ k: k, x: x, y: y[i] });
    });
    return out;
  }

  function draw(spec, length) {
    var years = length % 12 === 0;
    var step = length <= 12 ? 1 : length <= 24 ? 2 : 3;
    var ticks = d3.range(0, length, step);
    return Plot.plot({
      width: WIDTH, height: HEIGHT,
      marginLeft: 88, marginRight: 10, marginTop: 4, marginBottom: 64,
      style: {
        fontFamily: "Liberation Sans, Arial, Helvetica, sans-serif", fontSize: "17px",
        color: INK, background: "transparent", overflow: "visible"
      },
      x: {
        domain: [0, length], ticks: ticks, tickSize: 0, tickPadding: 12,
        tickFormat: function (d) { return years ? MONTHS[d % 12] : String(d + 1); },
        label: years ? "Month" : "Month of the loop",
        labelAnchor: "center", labelArrow: "none", labelOffset: 54
      },
      y: {
        domain: d3.extent(spec.y), nice: true, ticks: 5, tickSize: 0, tickPadding: 6,
        tickFormat: "~s", label: spec.ylab, labelAnchor: "center", labelArrow: "none", labelOffset: 78
      },
      marks: [
        Plot.frame({ fill: PANEL, stroke: "none" }),
        Plot.gridX(ticks, { stroke: "white", strokeOpacity: 1, strokeWidth: 1.5 }),
        Plot.gridY({ ticks: 5, stroke: "white", strokeOpacity: 1, strokeWidth: 1.5 }),
        Plot.line(loops(spec.month, spec.y, length), {
          x: "x", y: "y", z: "k", stroke: "black", strokeWidth: 1.6
        })
      ]
    });
  }

  function setup(el) {
    var spec = JSON.parse(el.querySelector("script").textContent);
    var controls = document.createElement("div");
    controls.className = "webr-slider-controls";
    controls.innerHTML =
      '<div class="webr-slider-input"><label>Loop length (months)</label>' +
      '<div class="webr-slider-track"><input type="range" aria-label="Loop length in months">' +
      '<output></output><div class="webr-slider-ticks"></div></div></div>';
    var code = document.createElement("div");
    code.className = "loop-slider-code";
    var plot = document.createElement("div");
    plot.className = "webr-slider-plot";
    var input = controls.querySelector("input");
    var min = 2;
    input.min = min;
    input.max = spec.max;
    input.step = 1;
    input.value = spec.value;
    [6, 12, 24, 36].forEach(function (t) {
      var tick = document.createElement("span");
      tick.textContent = t;
      tick.style.setProperty("--at", (t - min) / (spec.max - min));
      controls.querySelector(".webr-slider-ticks").append(tick);
    });
    el.append(code, plot, controls);

    function update() {
      var length = Number(input.value);
      controls.querySelector("output").textContent = length;
      input.parentNode.style.setProperty("--fill", (length - min) / (spec.max - min));
      code.textContent = "coord_loop(time_loops = months(" + length + "L))";
      plot.replaceChildren(draw(spec, length));
    }
    input.addEventListener("input", update);
    // Return the arrow keys to reveal.js for slide navigation after dragging
    input.addEventListener("pointerup", function () { input.blur(); });
    update();
  }

  function init() {
    document.querySelectorAll(".loop-slider").forEach(setup);
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
