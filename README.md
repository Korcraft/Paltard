# Paltard

A small paladin addon for the WoW Forever client. Its job: a **seal countdown**.

- Every seal lasts 30 seconds. When you cast one, Paltard starts a timer.
- For the last **5 seconds** (adjustable, 1-15) the seal's icon pops up with a countdown and a cooldown swipe, so you know to recast it before it fades.
- Casting a new seal restarts the timer with the new seal's icon. Casting Judgement uses up the seal, so the countdown stops.
- One movable icon frame, shared by every alert: unlock it to drag it anywhere and resize it with the mouse wheel. If more alerts are added later, they line up side by side around the same spot.
- Does nothing on other classes.

Not seen: a seal you right-click off or one an enemy dispels - the icon would still show for the rest of the 30 seconds. (The client hides buff data during combat, so Paltard works from your own casts, which are always visible.)

## Commands

- `/paltard` - settings window (also under Options > AddOns > Paltard)
- `/paltard unlock` / `/paltard lock` - move and resize the icon frame, or lock it
- `/paltard reset` - default position and size
- `/paltard test` - show a sample seal countdown
- `/paltard debug` - what seal tracking has recorded (copyable window)

## License

MIT
