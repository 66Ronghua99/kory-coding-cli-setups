# Scientific Slide Motion Patterns

Motion must clarify reasoning, not create spectacle. Default to no motion for reading-first reports.

## Supported patterns

### Short fade with minimal lift

Use for a title, figure, or conclusion entering as one unit.

```css
.reveal {
  opacity: 0;
  transform: translateY(8px);
  transition: opacity 180ms ease-out, transform 180ms ease-out;
}

.slide.visible .reveal {
  opacity: 1;
  transform: none;
}
```

### Evidence sequence

Use only when the order is part of the argument, such as hypothesis → observation → interpretation. Advance steps with a click or key; do not autoplay them.

```css
.reveal-step {
  opacity: 0;
  transition: opacity 160ms ease-out;
}

.reveal-step.is-visible {
  opacity: 1;
}
```

### Reduced motion

Every deck must include this rule after all animation declarations:

```css
@media (prefers-reduced-motion: reduce) {
  .reveal,
  .reveal-step {
    opacity: 1;
    transform: none;
    transition: none;
  }
}
```

## Timing limits

- Standard entry: 180 ms.
- Sequential evidence step: 160 ms.
- Maximum permitted transition: 220 ms.
- Stagger interval: 60–100 ms, only for a reasoning sequence.
- Slide changes: instant visibility switch; do not animate the whole stage.

## Prohibited patterns

Do not use particles, parallax, glow, bounce, elastic easing, cursor trails, 3D tilt, spinning, looping background animation, typewriter effects, or animated chart values. Do not delay access to evidence for decoration.
