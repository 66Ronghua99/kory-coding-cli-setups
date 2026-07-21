# Scientific HTML Presentation Template

Use this architecture for every generated scientific deck. The deck is authored at 1920×1080 and scaled as a single unit. Read `viewport-base.css` and paste its full contents into the deck’s `<style>` block.

## Required document structure

```html
<!DOCTYPE html>
<html lang="en" data-theme="institutional-blue">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Scientific Report</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;500;600;700&family=Source+Serif+4:wght@500;600&display=swap" rel="stylesheet">
  <style>
    /* === THEME: paste the selected block from SCIENCE_THEMES.md === */
    :root {
      --stage-bg: #d9e0e5;
      --slide-bg: #f4f7f8;
      --bg: #f4f7f8;
      --surface: #e6edf0;
      --text: #183149;
      --muted: #5f7180;
      --accent: #397775;
      --warning: #9a514b;
      --rule: #c5d1d7;
      --font-heading: "Source Sans 3", sans-serif;
      --font-body: "Source Sans 3", sans-serif;
      --title-size: 64px;
      --body-size: 30px;
      --citation-size: 20px;
      --chart-1: #285b75;
      --chart-2: #4c817d;
      --chart-3: #b07a45;
      --chart-4: #765b82;
      --chart-5: #758993;
      --chart-6: #a95454;
    }

    /* === RESET === */
    * { box-sizing: border-box; }
    h1, h2, h3, p, ul, ol, figure { margin: 0; }
    body { font-family: var(--font-body); color: var(--text); }

    /* === FIXED STAGE === */
    /* Paste the complete local viewport-base.css here. */

    /* === SCIENTIFIC LAYOUT === */
    .slide {
      padding: 72px 84px 60px;
      color: var(--text);
      font-family: var(--font-body);
    }
    .slide-header {
      display: flex;
      align-items: baseline;
      justify-content: space-between;
      gap: 36px;
      padding-bottom: 20px;
      border-bottom: 2px solid var(--rule);
    }
    .slide-title {
      max-width: 1480px;
      font-family: var(--font-heading);
      font-size: var(--title-size);
      font-weight: 600;
      line-height: 1.08;
      letter-spacing: -0.018em;
    }
    .section-label {
      color: var(--accent);
      font-size: 22px;
      font-weight: 700;
      letter-spacing: 0.1em;
      text-transform: uppercase;
      white-space: nowrap;
    }
    .slide-body {
      height: 760px;
      padding-top: 34px;
      font-size: var(--body-size);
      line-height: 1.42;
    }
    .two-column {
      display: grid;
      grid-template-columns: minmax(0, 1.22fr) minmax(0, 0.78fr);
      gap: 44px;
    }
    .figure-panel,
    .evidence-panel {
      min-width: 0;
      min-height: 0;
      padding: 30px;
      border: 1px solid var(--rule);
      border-radius: 10px;
      background: var(--surface);
    }
    .figure-panel {
      display: grid;
      grid-template-rows: 1fr auto;
      gap: 18px;
    }
    .figure-panel svg,
    .figure-panel img {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }
    .figure-caption {
      color: var(--muted);
      font-size: 22px;
      line-height: 1.35;
    }
    .key-result {
      padding-left: 26px;
      border-left: 5px solid var(--accent);
    }
    .key-result strong {
      display: block;
      margin-bottom: 14px;
      color: var(--accent);
      font-size: 72px;
      font-weight: 600;
      line-height: 1;
    }
    .interpretation {
      margin-top: 34px;
      padding-top: 28px;
      border-top: 2px solid var(--rule);
    }
    .interpretation h3 {
      margin-bottom: 12px;
      color: var(--muted);
      font-size: 22px;
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }
    .source-footer {
      position: absolute;
      left: 84px;
      right: 84px;
      bottom: 24px;
      color: var(--muted);
      font-size: var(--citation-size);
      line-height: 1.3;
    }
    .speaker-notes { display: none; }

    /* === RESTRAINED MOTION === */
    .reveal {
      opacity: 0;
      transform: translateY(8px);
      transition: opacity 180ms ease-out, transform 180ms ease-out;
    }
    .slide.visible .reveal { opacity: 1; transform: none; }
    @media (prefers-reduced-motion: reduce) {
      .reveal { opacity: 1; transform: none; transition: none; }
    }

    /* === OUTSIDE-STAGE CONTROLS === */
    .page-counter,
    .notes-panel,
    .edit-toggle,
    .edit-hotzone {
      position: fixed;
      z-index: 10000;
      font-family: var(--font-body);
    }
    .page-counter {
      right: 18px;
      bottom: 14px;
      padding: 6px 10px;
      border-radius: 6px;
      background: rgba(12, 22, 30, 0.8);
      color: #fff;
      font-size: 14px;
    }
    .edit-hotzone { top: 0; left: 0; width: 80px; height: 80px; }
    .edit-toggle {
      top: 14px;
      left: 14px;
      padding: 8px 12px;
      border: 1px solid rgba(255,255,255,.35);
      border-radius: 6px;
      background: rgba(12,22,30,.88);
      color: #fff;
      opacity: 0;
      pointer-events: none;
      transition: opacity 180ms ease-out;
    }
    .edit-toggle.show,
    .edit-toggle.active { opacity: 1; pointer-events: auto; }
    .notes-panel {
      right: 18px;
      top: 18px;
      width: min(520px, calc(100vw - 36px));
      max-height: calc(100vh - 72px);
      overflow: auto;
      padding: 18px;
      border-radius: 8px;
      background: rgba(12,22,30,.94);
      color: #fff;
      font-size: 16px;
      line-height: 1.45;
    }
    [contenteditable="true"] { outline: 3px solid var(--accent); outline-offset: 3px; }
  </style>
</head>
<body>
  <div class="deck-viewport">
    <main class="deck-stage" id="deckStage">
      <section class="slide active visible" data-slide-type="title">
        <div class="section-label reveal">Scientific report</div>
        <h1 class="slide-title reveal">Research question stated without theatrical scale</h1>
        <p class="reveal">Author · Institution · Date</p>
        <aside class="speaker-notes">State the decision or question that motivates the work.</aside>
      </section>

      <section class="slide" data-slide-type="result">
        <header class="slide-header">
          <h2 class="slide-title reveal">Treatment reduced median response time by 4.6 minutes</h2>
          <span class="section-label">Result 01</span>
        </header>
        <div class="slide-body two-column">
          <figure class="figure-panel reveal">
            <svg role="img" aria-label="Directly labeled comparison plot"><!-- Evidence figure --></svg>
            <figcaption class="figure-caption">Median with 95% confidence interval; control n=40, treatment n=42.</figcaption>
          </figure>
          <div class="evidence-panel reveal">
            <div class="key-result"><strong>−4.6 min</strong><p>95% CI [−6.8, −2.4]</p></div>
            <div class="interpretation"><h3>Interpretation</h3><p>The observed difference is compatible with a meaningful reduction in this single-center sample.</p></div>
          </div>
        </div>
        <footer class="source-footer">Source: Results §3.2, Figure 2.</footer>
        <aside class="speaker-notes">Describe the effect before discussing significance. Preserve the single-center limitation.</aside>
      </section>
    </main>
  </div>

  <div class="edit-hotzone" aria-hidden="true"></div>
  <button class="edit-toggle" id="editToggle" type="button">Edit</button>
  <div class="page-counter" id="pageCounter" aria-live="polite"></div>
  <div class="notes-panel" id="notesPanel" hidden></div>

  <script>
    /* === PRESENTATION CONTROLLER === */
    class SlidePresentation {
      constructor() {
        this.slides = [...document.querySelectorAll('.slide')];
        this.stage = document.getElementById('deckStage');
        this.counter = document.getElementById('pageCounter');
        this.notesPanel = document.getElementById('notesPanel');
        this.index = 0;
        this.touchStartX = null;
        this.wheelLocked = false;
        this.scaleStage = this.scaleStage.bind(this);
        this.bindInputs();
        this.scaleStage();
        this.goToSlide(0);
      }

      scaleStage() {
        const factor = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
        const x = (window.innerWidth - 1920 * factor) / 2;
        const y = (window.innerHeight - 1080 * factor) / 2;
        this.stage.style.transform = `translate(${x}px, ${y}px) scale(${factor})`;
      }

      goToSlide(nextIndex) {
        this.index = Math.max(0, Math.min(nextIndex, this.slides.length - 1));
        this.slides.forEach((slide, slideIndex) => {
          const active = slideIndex === this.index;
          slide.classList.toggle('active', active);
          slide.classList.toggle('visible', active);
        });
        this.counter.textContent = `${this.index + 1} / ${this.slides.length}`;
        this.updateNotes();
      }

      updateNotes() {
        const notes = this.slides[this.index].querySelector('.speaker-notes');
        this.notesPanel.textContent = notes ? notes.textContent.trim() : 'No speaker notes for this slide.';
      }

      isEditingTarget(target) {
        return target instanceof HTMLElement && (target.isContentEditable || /INPUT|TEXTAREA|SELECT/.test(target.tagName));
      }

      bindInputs() {
        window.addEventListener('resize', this.scaleStage);
        document.addEventListener('keydown', event => {
          if (this.isEditingTarget(event.target)) return;
          if (['ArrowRight', 'ArrowDown', ' ', 'PageDown'].includes(event.key)) {
            event.preventDefault();
            this.goToSlide(this.index + 1);
          } else if (['ArrowLeft', 'ArrowUp', 'PageUp'].includes(event.key)) {
            event.preventDefault();
            this.goToSlide(this.index - 1);
          } else if (event.key === 'Home') {
            this.goToSlide(0);
          } else if (event.key === 'End') {
            this.goToSlide(this.slides.length - 1);
          } else if (event.key.toLowerCase() === 'n') {
            this.notesPanel.hidden = !this.notesPanel.hidden;
          }
        });
        document.addEventListener('touchstart', event => {
          this.touchStartX = event.changedTouches[0].clientX;
        }, { passive: true });
        document.addEventListener('touchend', event => {
          if (this.touchStartX === null) return;
          const delta = event.changedTouches[0].clientX - this.touchStartX;
          if (Math.abs(delta) > 50) this.goToSlide(this.index + (delta < 0 ? 1 : -1));
          this.touchStartX = null;
        }, { passive: true });
        document.addEventListener('wheel', event => {
          if (this.wheelLocked || Math.abs(event.deltaY) < 24) return;
          this.wheelLocked = true;
          this.goToSlide(this.index + (event.deltaY > 0 ? 1 : -1));
          window.setTimeout(() => { this.wheelLocked = false; }, 350);
        }, { passive: true });
      }
    }

    /* === INLINE EDITOR === */
    class SlideEditor {
      constructor(presentation) {
        this.presentation = presentation;
        this.active = false;
        this.toggle = document.getElementById('editToggle');
        this.hotzone = document.querySelector('.edit-hotzone');
        this.hideTimer = null;
        this.bind();
        this.restore();
      }

      editableNodes() {
        return [...document.querySelectorAll('.slide h1, .slide h2, .slide h3, .slide p, .slide li, .slide figcaption, .source-footer')];
      }

      setActive(next) {
        this.active = next;
        this.toggle.classList.toggle('active', next);
        this.toggle.textContent = next ? 'Done' : 'Edit';
        this.editableNodes().forEach(node => node.contentEditable = String(next));
        if (!next) this.save();
      }

      save() {
        const content = this.editableNodes().map(node => node.innerHTML);
        localStorage.setItem(`scientific-deck:${document.title}`, JSON.stringify(content));
      }

      restore() {
        const saved = localStorage.getItem(`scientific-deck:${document.title}`);
        if (!saved) return;
        const content = JSON.parse(saved);
        this.editableNodes().forEach((node, index) => {
          if (typeof content[index] === 'string') node.innerHTML = content[index];
        });
      }

      bind() {
        this.toggle.addEventListener('click', () => this.setActive(!this.active));
        this.hotzone.addEventListener('click', () => this.setActive(!this.active));
        this.hotzone.addEventListener('mouseenter', () => {
          clearTimeout(this.hideTimer);
          this.toggle.classList.add('show');
        });
        this.hotzone.addEventListener('mouseleave', () => {
          this.hideTimer = setTimeout(() => {
            if (!this.active) this.toggle.classList.remove('show');
          }, 400);
        });
        this.toggle.addEventListener('mouseenter', () => clearTimeout(this.hideTimer));
        this.toggle.addEventListener('mouseleave', () => {
          this.hideTimer = setTimeout(() => {
            if (!this.active) this.toggle.classList.remove('show');
          }, 400);
        });
        document.addEventListener('keydown', event => {
          if (event.target instanceof HTMLElement && event.target.isContentEditable) {
            if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 's') {
              event.preventDefault();
              this.save();
            }
            return;
          }
          if (event.key.toLowerCase() === 'e') this.setActive(!this.active);
        });
      }
    }

    window.presentation = new SlidePresentation();
    window.editor = new SlideEditor(window.presentation);
  </script>
</body>
</html>
```

## Generation rules

- Include the full contents of local `viewport-base.css`; the comment marker is not valid in a delivered deck.
- Keep CSS and JavaScript inline. Use relative `assets/` paths for numerous local figures.
- Use `data-slide-type` values: `title`, `question`, `study-design`, `method`, `result`, `comparison`, `limitation`, `conclusion`, `references`, and `appendix`.
- Do not use `display: none` to switch slides. Visibility is controlled by `.active` / `.visible`.
- Keep controls outside `.deck-stage`; the stage itself remains exactly 1920×1080.
- A result page must pair a conclusion title with evidence, uncertainty, interpretation, and source.
- Test for overflow and geometric overlap; `scrollHeight` alone cannot detect one grid panel covering another.
