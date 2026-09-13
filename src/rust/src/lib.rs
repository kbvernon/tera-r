use extendr_api::{prelude::*, thread_safety::stop};
use serde_json::Value;
use std::fs;
use std::io::BufWriter;
use tera::{Context, Delimiters, Tera};
use tera_contrib::*;

#[derive(Debug)]
#[extendr]
struct RTera(Tera);

#[extendr]
impl RTera {
    fn new() -> Self {
        let mut tera = Tera::default();
        register_all(&mut tera);
        RTera(tera)
    }

    fn new_from_glob(glob: &str) -> Self {
        let mut tera = Tera::default();
        register_all(&mut tera);
        tera.load_from_glob(glob)
            .unwrap_or_else(|e| stop(&e.to_string()));
        RTera(tera)
    }

    fn full_reload(&mut self) {
        self.0
            .full_reload()
            .unwrap_or_else(|e| stop(&e.to_string()))
    }

    fn add_string_templates(&mut self, templates: List) {
        let mut template_tuples: Vec<(&str, &str)> = vec![];

        for (name, content) in templates.iter() {
            template_tuples.push((name, &content.as_str().unwrap()))
        }

        self.0
            .add_raw_templates(template_tuples)
            .unwrap_or_else(|e| stop(&e.to_string()))
    }

    fn add_file_templates(&mut self, templates: List) {
        let mut template_tuples: Vec<(&str, Option<&str>)> = vec![];

        for (name, content) in templates.iter() {
            let template_name = if name.is_empty() { None } else { Some(name) };
            template_tuples.push((&content.as_str().unwrap(), template_name))
        }

        self.0
            .add_template_files(template_tuples)
            .unwrap_or_else(|e| stop(&e.to_string()))
    }

    fn render_template_to_file(
        &self,
        template_name: &str,
        context_string: &str,
        outfile: &str,
    ) -> String {
        let context = to_context(context_string);
        let file = fs::File::create(outfile).unwrap_or_else(|e| stop(&e.to_string()));
        let mut writer = BufWriter::new(file);

        match self.0.render_to(template_name, &context, &mut writer) {
            Ok(_) => outfile.into(),
            Err(e) => stop(&e.to_string()),
        }
    }

    fn render_template_to_string(&self, template_name: &str, context_string: &str) -> String {
        let context = to_context(context_string);

        match self.0.render(template_name, &context) {
            Ok(result) => result.into(),
            Err(e) => stop(&e.to_string()),
        }
    }

    fn render_component_to_file(
        &self,
        component_name: &str,
        context_string: &str,
        body: Option<&str>,
        autoescape: bool,
        outfile: &str,
    ) -> String {
        let context = to_context(context_string);
        let file = fs::File::create(outfile).unwrap_or_else(|e| stop(&e.to_string()));
        let mut writer = BufWriter::new(file);

        match self
            .0
            .render_component_to(component_name, &context, body, autoescape, &mut writer)
        {
            Ok(_) => outfile.into(),
            Err(e) => stop(&e.to_string()),
        }
    }

    fn render_component_to_string(
        &self,
        component_name: &str,
        context_string: &str,
        body: Option<&str>,
        autoescape: bool,
    ) -> String {
        let context = to_context(context_string);

        match self
            .0
            .render_component(component_name, &context, body, autoescape)
        {
            Ok(result) => result.into(),
            Err(e) => stop(&e.to_string()),
        }
    }

    fn render_block_to_file(
        &self,
        template_name: &str,
        block_name: &str,
        context_string: &str,
        outfile: &str,
    ) -> String {
        let context = to_context(context_string);
        let file = fs::File::create(outfile).unwrap_or_else(|e| stop(&e.to_string()));
        let mut writer = BufWriter::new(file);

        match self
            .0
            .render_block_to(template_name, block_name, &context, &mut writer)
        {
            Ok(_) => outfile.into(),
            Err(e) => stop(&e.to_string()),
        }
    }

    fn render_block_to_string(
        &self,
        template_name: &str,
        block_name: &str,
        context_string: &str,
    ) -> String {
        let context = to_context(context_string);

        match self.0.render_block(template_name, block_name, &context) {
            Ok(result) => result.into(),
            Err(e) => stop(&e.to_string()),
        }
    }

    fn render_string_to_file(
        &self,
        template_string: &str,
        context_string: &str,
        autoescape: bool,
        outfile: &str,
    ) -> String {
        let context = to_context(context_string);
        let file = fs::File::create(outfile).unwrap_or_else(|e| stop(&e.to_string()));
        let mut writer = BufWriter::new(file);

        match self
            .0
            .render_str_to(template_string, &context, autoescape, &mut writer)
        {
            Ok(_) => outfile.into(),
            Err(e) => stop(&e.to_string()),
        }
    }

    fn render_string_to_string(
        &self,
        template_string: &str,
        context_string: &str,
        autoescape: bool,
    ) -> String {
        let context = to_context(context_string);
        match self.0.render_str(template_string, &context, autoescape) {
            Ok(result) => result.into(),
            Err(e) => stop(&e.to_string()),
        }
    }

    fn autoescape_on(&mut self) {
        self.0.reset_escape_fn();
        self.0.autoescape_on([".html", ".htm", ".xml"])
    }

    fn autoescape_off(&mut self) {
        self.0.autoescape_on(Vec::<&str>::new())
    }

    fn set_delimiters(&mut self, delimiters: List) {
        let mut d = Delimiters::default();

        for (name, value) in delimiters.iter() {
            let value = match value.as_str() {
                Some(s) => s.to_string().into(),
                None => stop(&format!("Delimiter `{}` must be a string.", name)),
            };
            match name {
                "block_start" => d.block_start = value,
                "block_end" => d.block_end = value,
                "variable_start" => d.variable_start = value,
                "variable_end" => d.variable_end = value,
                "comment_start" => d.comment_start = value,
                "comment_end" => d.comment_end = value,
                _ => stop(&format!("Unknown delimiter `{}`.", name)),
            }
        }

        self.0
            .set_delimiters(d)
            .unwrap_or_else(|e| stop(&e.to_string()))
    }

    fn set_globals(&mut self, context_string: &str) {
        *self.0.global_context() = to_context(context_string)
    }

    fn clear_globals(&mut self) {
        *self.0.global_context() = Context::new()
    }

    fn get_templates(&self) -> Strings {
        self.0.get_template_names().collect()
    }

    fn get_variables(&self, template_name: &str) -> Strings {
        self.0
            .get_template_variables(template_name)
            .unwrap_or_else(|e| stop(&e.to_string()))
            .into_iter()
            .collect()
    }

    fn get_components(&self) -> Strings {
        self.0.get_component_names().collect()
    }
}

fn to_context(x: &str) -> Context {
    let value: Value = serde_json::from_str(x).unwrap_or_else(|e| stop(&e.to_string()));
    Context::from_serialize(&value).unwrap_or_else(|e| stop(&e.to_string()))
}

pub fn register_all(tera: &mut Tera) {
    tera.register_filter("b64_encode", base64::b64_encode);
    tera.register_filter("b64_decode", base64::b64_decode);
    tera.register_filter("date", dates::date);
    tera.register_function("now", dates::now);
    tera.register_test("before", dates::is_before);
    tera.register_test("after", dates::is_after);
    tera.register_filter("filesize_format", filesize_format::filesize_format);
    tera.register_filter("format", format::format);
    tera.register_filter("json_encode", json::json_encode);
    tera.register_function("get_random", rand::get_random);
    tera.register_filter("shuffle", rand::shuffle);
    tera.register_filter("striptags", regex::striptags);
    tera.register_filter("spaceless", regex::spaceless);
    tera.register_filter("regex_replace", regex::RegexReplace::default());
    tera.register_test("matching", regex::Matching::default());
    tera.register_filter("slug", slug::slug);
    tera.register_filter("urlencode", urlencode::urlencode);
    tera.register_filter("urlencode_strict", urlencode::urlencode_strict);
}

// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {
    mod rtera;
    impl RTera;
}
