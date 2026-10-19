#![cfg_attr(target_os = "windows", windows_subsystem = "windows")]
use gpui_kit::component::{
    ActiveTheme, Theme, ThemeMode,
    button::{Button, ButtonVariants},
};
use gpui_kit::*;

const APP_NAME: &str = env!("CARGO_PKG_DESCRIPTION");

gpui_kit::actions!(app, [Quit]);

struct StarterApp {
    count: u32,
}

impl Render for StarterApp {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme();
        div()
            .size_full()
            .flex()
            .flex_col()
            .items_center()
            .justify_center()
            .gap_4()
            .bg(theme.background)
            .text_color(theme.foreground)
            .child(
                div()
                    .text_xl()
                    .font_weight(FontWeight::SEMIBOLD)
                    .child(APP_NAME),
            )
            .child(
                div()
                    .text_color(theme.muted_foreground)
                    .child(format!("Clicked {} times", self.count)),
            )
            .child(
                Button::new("count")
                    .primary()
                    .cursor_pointer()
                    .label("Click me")
                    .on_click(cx.listener(|this, _, _, cx| {
                        this.count += 1;
                        cx.notify();
                    })),
            )
    }
}

fn main() {
    application().with_assets(assets::Assets).run(|cx| {
        init(cx);
        Theme::change(ThemeMode::Dark, None, cx);
        cx.on_action(|_: &Quit, cx| cx.quit());
        cx.bind_keys([KeyBinding::new("secondary-q", Quit, None)]);
        cx.on_window_closed(|cx, _| {
            if cx.windows().is_empty() {
                cx.quit();
            }
        })
        .detach();
        let options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds::centered(
                None,
                size(px(480.), px(320.)),
                cx,
            ))),
            ..Default::default()
        };
        open_window(options, cx, |window, cx| {
            window.set_window_title(APP_NAME);
            cx.new(|_| StarterApp { count: 0 })
        })
        .expect("Could not open the window");
        cx.activate(true);
    });
}
