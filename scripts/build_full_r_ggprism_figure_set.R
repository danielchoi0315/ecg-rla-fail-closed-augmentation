#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(ggprism)
  library(jsonlite)
  library(patchwork)
  library(readr)
  library(scales)
  library(svglite)
  library(tidyr)
})

args <- commandArgs(trailingOnly = FALSE)
script_file <- sub("^--file=", "", args[grep("^--file=", args)])
script_dir <- if (length(script_file) == 0) getwd() else dirname(normalizePath(script_file, winslash = "/", mustWork = TRUE))
root <- normalizePath(file.path(script_dir, ".."), winslash = "/", mustWork = TRUE)
tab_dir <- file.path(root, "data", "locked_tables")
multi_dir <- file.path(root, "data", "multicohort")
main_dir <- file.path(root, "figures", "final_locked")
supp_dir <- file.path(root, "figures", "supplementary_locked")
png_dir <- file.path(root, "figures", "journal_png")
tiff_dir <- file.path(root, "figures", "journal_tiff")
dir.create(main_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(supp_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(png_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tiff_dir, recursive = TRUE, showWarnings = FALSE)

col <- c(
  rla = "#4E8FDA",
  utility = "#3FAE2A",
  fixed = "#C65DAA",
  real = "#30343B",
  orange = "#E46F37",
  muted_orange = "#C76B39",
  gray = "#7B8790",
  light = "#EEF2F5",
  band = "#F7F9FA",
  ink = "#202A33"
)

policy_cols <- c(
  "Certified RLA" = unname(col["rla"]),
  "Utility-only" = unname(col["utility"]),
  "Always-on r=0.10" = unname(col["fixed"]),
  "Fixed r=0.10" = unname(col["fixed"])
)
model_cols <- c(
  "Real-only" = unname(col["real"]),
  "RLA-selected" = unname(col["rla"]),
  "Review all" = unname(col["orange"]),
  "Review none" = unname(col["gray"])
)

theme_pub <- function(base_size = 9.5) {
  theme_prism(base_family = "Arial", base_size = base_size, border = FALSE) +
    theme(
      plot.title = element_text(size = base_size + 1.6, face = "bold", hjust = 0, margin = margin(b = 5), color = col["ink"]),
      axis.title = element_text(size = base_size + 0.5, color = col["ink"], margin = margin(t = 4)),
      axis.text = element_text(size = base_size - 0.3, color = col["ink"]),
      axis.line = element_line(color = col["ink"], linewidth = 0.38),
      axis.ticks = element_line(color = col["ink"], linewidth = 0.32),
      panel.grid.major = element_line(color = col["light"], linewidth = 0.28),
      panel.grid.minor = element_blank(),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      legend.position = "top",
      legend.title = element_blank(),
      legend.text = element_text(size = base_size - 0.2, color = col["ink"]),
      legend.key.height = unit(0.28, "cm"),
      legend.key.width = unit(0.42, "cm"),
      legend.margin = margin(0, 0, 0, 0),
      plot.margin = margin(5, 8, 5, 8)
    )
}

save_plot <- function(plot, stem, dir = main_dir, width = 10, height = 5.5, dpi = 800) {
  pdf_path <- file.path(dir, paste0(stem, ".pdf"))
  svg_path <- file.path(dir, paste0(stem, ".svg"))
  png_path <- file.path(png_dir, paste0(stem, ".png"))
  tif_path <- file.path(tiff_dir, paste0(stem, ".tiff"))
  ggsave(pdf_path, plot, device = cairo_pdf, width = width, height = height, units = "in", bg = "white")
  ggsave(svg_path, plot, device = svglite::svglite, width = width, height = height, units = "in", bg = "white")
  ggsave(png_path, plot, device = ragg::agg_png, width = width, height = height, units = "in", dpi = dpi, bg = "white")
  ggsave(tif_path, plot, device = ragg::agg_tiff, width = width, height = height, units = "in", dpi = dpi, compression = "lzw", bg = "white")
  invisible(c(pdf = pdf_path, svg = svg_path, png = png_path, tiff = tif_path))
}

label_model <- function(x) recode(x, real_only = "Real-only", rla_selected = "RLA-selected", treat_all = "Review all", treat_none = "Review none")
label_policy <- function(x) recode(x, baseline_rla = "Certified RLA", no_cert = "Utility-only", always_aug_r010 = "Always-on r=0.10")

row_bands <- tibble(ymin = c(3.5, 1.5), ymax = c(4.5, 2.5))
dataset_levels <- c("ECG-Arrhythmia\n(primary)", "CPSC2018", "Chapman-\nShaoxing", "G12EC")

make_dot_panel <- function(data, x, xmin, xmax, title, xlab, xlim, breaks, show_y = FALSE, zero = FALSE) {
  ggplot(data, aes(y = y, color = policy, shape = policy)) +
    geom_rect(data = row_bands, aes(xmin = -Inf, xmax = Inf, ymin = ymin, ymax = ymax), inherit.aes = FALSE, fill = col["band"], color = NA) +
    geom_hline(yintercept = c(1.5, 2.5, 3.5), color = "#E3E8EC", linewidth = 0.25) +
    {if (zero) geom_vline(xintercept = 0, color = "#5E6A72", linewidth = 0.34)} +
    geom_segment(aes(x = {{ xmin }}, xend = {{ xmax }}, yend = y), linewidth = 0.56, alpha = 0.9, lineend = "round") +
    geom_point(aes(x = {{ x }}), size = 2.25, stroke = 0.2) +
    scale_y_continuous(
      limits = c(0.55, 4.55), breaks = 4:1,
      labels = if (show_y) dataset_levels else rep("", 4), expand = c(0, 0)
    ) +
    scale_x_continuous(limits = xlim, breaks = breaks, expand = expansion(mult = c(0.015, 0.025))) +
    scale_color_manual(values = policy_cols, drop = FALSE) +
    scale_shape_manual(values = c("Certified RLA" = 16, "Utility-only" = 15, "Always-on r=0.10" = 17), drop = FALSE) +
    labs(title = title, x = xlab, y = NULL) +
    theme_pub(9.7) +
    theme(axis.ticks.y = element_blank(), axis.line.y = element_blank(), panel.grid.major.y = element_blank())
}

# Figure 1: pass through the curated schematic, do not regenerate.
fig1_src <- file.path(main_dir, "Figure1_study_design_fail_closed_certification.pdf")
if (!file.exists(fig1_src)) {
  warning("Figure 1 schematic is not present at: ", fig1_src)
}

# Figure 2: multicohort policy validation.
multi <- read_csv(file.path(multi_dir, "multicohort_policy_overall_for_professional_figure.csv"), show_col_types = FALSE) %>%
  mutate(
    dataset_label = factor(case_when(
      dataset == "ecgarr" ~ "ECG-Arrhythmia\n(primary)",
      dataset == "cpsc2018" ~ "CPSC2018",
      dataset == "chapman_shaoxing" ~ "Chapman-\nShaoxing",
      dataset == "g12ec" ~ "G12EC",
      TRUE ~ dataset
    ), levels = dataset_levels),
    y_base = as.numeric(recode(as.character(dataset_label),
      "ECG-Arrhythmia\n(primary)" = "4",
      "CPSC2018" = "3",
      "Chapman-\nShaoxing" = "2",
      "G12EC" = "1"
    )),
    policy = factor(policy, levels = c("Certified RLA", "Utility-only", "Always-on r=0.10")),
    offset = recode(as.character(policy), "Certified RLA" = 0.2, "Utility-only" = 0, "Always-on r=0.10" = -0.2),
    y = y_base + as.numeric(offset)
  )

fig2 <- (
  make_dot_panel(multi, delta_pp, delta_pp_lo, delta_pp_hi, "a) External gain", "Macro-AUPRC delta (percentage points)", c(-2.25, 1.55), c(-2, -1, 0, 1), TRUE, TRUE) |
    make_dot_panel(multi, harm_pct, harm_pct_lo, harm_pct_hi, "b) Any performance harm", "Cells with delta < 0 (%)", c(0, 82), c(0, 20, 40, 60, 80), FALSE, FALSE)
) / (
  make_dot_panel(multi, severe_pct, severe_pct_lo, severe_pct_hi, "c) Severe harm", "Cells with delta < -0.01 (%)", c(0, 64), c(0, 20, 40, 60), TRUE, FALSE) |
    make_dot_panel(multi, deploy_pct, deploy_pct_lo, deploy_pct_hi, "d) Augmentation authorized", "Cells using synthetic augmentation (%)", c(0, 103), c(0, 25, 50, 75, 100), FALSE, FALSE)
) + plot_layout(guides = "collect") & theme(legend.position = "top")
save_plot(fig2, "Figure2_external_multicohort_policy_validation_locked", main_dir, 10, 5.5)

# Figure 3: patient-level any-abnormal evaluation.
metric_source <- read_csv(file.path(tab_dir, "primary_any_abnormal_patient_level_metric_summary.csv"), show_col_types = FALSE) %>%
  filter(stage == "calibrated") %>%
  slice(1)
metric <- tibble(
    metric = c("AUROC", "AUPRC", "Brier reduction", "ECE15 reduction"),
    improvement = c(metric_source$delta_auroc, metric_source$delta_auprc, -metric_source$delta_brier, -metric_source$delta_ece15),
    label = c(sprintf("+%.3f", metric_source$delta_auroc), sprintf("+%.3f", metric_source$delta_auprc), sprintf("+%.3f", -metric_source$delta_brier), sprintf("+%.3f", -metric_source$delta_ece15))
  ) %>%
  mutate(metric = factor(metric, levels = rev(metric)))

p3a <- ggplot(metric, aes(improvement, metric)) +
  geom_col(width = 0.46, fill = col["rla"], alpha = 0.88) +
  geom_text(aes(label = label), hjust = -0.18, size = 3.0, family = "Arial", color = col["ink"]) +
  scale_x_continuous(limits = c(0, 0.11), breaks = c(0, 0.025, 0.05, 0.075, 0.10), labels = label_number(accuracy = 0.025)) +
  labs(title = "a) Patient-level improvement", x = "Direction-adjusted improvement", y = NULL) +
  theme_pub(9.5) + theme(panel.grid.major.y = element_blank())

rel <- read_csv(file.path(tab_dir, "primary_any_abnormal_calibration_reliability_summary.csv"), show_col_types = FALSE) %>%
  filter(stage == "calibrated", count > 0) %>%
  mutate(model_label = factor(label_model(model), levels = c("Real-only", "RLA-selected")))
p3b <- ggplot(rel, aes(mean_prob, frac_pos, color = model_label)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "#9AA5AD", linewidth = 0.42) +
  geom_line(linewidth = 0.58) +
  geom_point(size = 1.45) +
  annotate("text", x = 0.62, y = 0.91, label = "RLA-selected", color = unname(col["rla"]), family = "Arial", size = 2.7, hjust = 0) +
  annotate("text", x = 0.62, y = 0.79, label = "Real-only", color = unname(col["real"]), family = "Arial", size = 2.7, hjust = 0) +
  scale_color_manual(values = model_cols) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE) +
  labs(title = "b) Calibration", x = "Predicted probability", y = "Observed fraction") +
  theme_pub(9.5) + theme(legend.position = "none")

tri <- read_csv(file.path(tab_dir, "triage_budget_1_5_10_20.csv"), show_col_types = FALSE) %>%
  filter(endpoint == "any_abnormal", stage == "calibrated", budget_frac %in% c(0.05, 0.10, 0.20)) %>%
  select(model, budget_frac, tp_per_1000, fp_per_1000) %>%
  pivot_wider(names_from = model, values_from = c(tp_per_1000, fp_per_1000)) %>%
  transmute(
    budget = budget_frac * 100,
    `True positives` = tp_per_1000_rla_selected - tp_per_1000_real_only,
    `False positives` = fp_per_1000_rla_selected - fp_per_1000_real_only
  ) %>%
  pivot_longer(-budget, names_to = "quantity", values_to = "change") %>%
  mutate(quantity = factor(quantity, levels = c("True positives", "False positives")))
p3c <- ggplot(tri, aes(budget, change, color = quantity)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#9AA5AD", linewidth = 0.38) +
  geom_line(linewidth = 0.62) +
  geom_point(size = 2.1) +
  geom_text(data = tri %>% filter(budget == 20), aes(label = quantity), hjust = -0.08, size = 2.65, family = "Arial", show.legend = FALSE) +
  scale_color_manual(values = c("True positives" = unname(col["rla"]), "False positives" = unname(col["orange"])), guide = "none") +
  scale_x_continuous(limits = c(4, 24), breaks = c(5, 10, 20), labels = function(x) paste0(x, "%")) +
  scale_y_continuous(limits = c(-10, 10), breaks = c(-10, -5, 0, 5, 10)) +
  labs(title = "c) Offline triage proxy", x = "Review budget", y = "Change vs real-only per 1000 ECGs") +
  theme_pub(9.5)

dca <- read_csv(file.path(tab_dir, "dca_all_endpoints.csv"), show_col_types = FALSE) %>%
  filter(endpoint == "any_abnormal", stage == "calibrated", threshold <= 0.50) %>%
  mutate(model_label = factor(label_model(model), levels = c("Review all", "RLA-selected", "Real-only", "Review none")))
dca_labels <- tibble(
  model_label = factor(c("RLA-selected", "Review all", "Real-only", "Review none"), levels = c("Review all", "RLA-selected", "Real-only", "Review none")),
  x = c(51, 51, 51, 51),
  y = c(0.385, 0.355, 0.315, 0.018),
  label = c("RLA-selected", "Review all", "Real-only", "Review none")
)
p3d <- ggplot(dca, aes(threshold * 100, net_benefit, color = model_label, fill = model_label)) +
  geom_ribbon(data = dca %>% filter(model %in% c("real_only", "rla_selected")), aes(ymin = net_benefit_ci_low, ymax = net_benefit_ci_high), alpha = 0.12, linewidth = 0) +
  geom_line(aes(linetype = model_label), linewidth = 0.64) +
  geom_text(
    data = dca_labels,
    aes(x = x, y = y, label = label, color = model_label),
    inherit.aes = FALSE,
    hjust = 0,
    size = 2.55,
    family = "Arial",
    show.legend = FALSE
  ) +
  scale_color_manual(values = model_cols) +
  scale_fill_manual(values = model_cols) +
  scale_linetype_manual(values = c("Review all" = "solid", "RLA-selected" = "solid", "Real-only" = "solid", "Review none" = "dashed")) +
  scale_x_continuous(limits = c(0, 59), breaks = seq(0, 50, 10), labels = function(x) paste0(x, "%")) +
  labs(title = "d) Exploratory decision curve", x = "Threshold probability", y = "Net benefit") +
  theme_pub(9.5) + guides(color = "none", fill = "none", linetype = "none")

fig3 <- (p3a | p3b) / (p3c | p3d)
save_plot(fig3, "Figure3_patient_any_abnormal_offline_triage_locked", main_dir, 10, 5.5)

# Figure 4: transportability, subgroup, and stress-test limits.
transport_source <- read_csv(file.path(tab_dir, "transportability_uncertainty.csv"), show_col_types = FALSE) %>%
  filter(stage == "calibrated", model == "rla_selected")
trans <- bind_rows(
  transport_source %>%
    transmute(
      item = if_else(endpoint == "any_abnormal", "Any abnormal: AUROC", "MI secondary: AUROC"),
      delta = delta_vs_real_only_auroc_mean * 100,
      lo = delta_vs_real_only_auroc_p2p5 * 100,
      hi = delta_vs_real_only_auroc_p97p5 * 100,
      endpoint
    ),
  transport_source %>%
    transmute(
      item = if_else(endpoint == "any_abnormal", "Any abnormal: AUPRC", "MI secondary: AUPRC"),
      delta = delta_vs_real_only_auprc_mean * 100,
      lo = delta_vs_real_only_auprc_p2p5 * 100,
      hi = delta_vs_real_only_auprc_p97p5 * 100,
      endpoint
    )
) %>%
  mutate(item = factor(item, levels = rev(c("Any abnormal: AUROC", "Any abnormal: AUPRC", "MI secondary: AUROC", "MI secondary: AUPRC"))))
p4a <- ggplot(trans, aes(delta, item)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "#9AA5AD", linewidth = 0.38) +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.13, color = col["gray"], linewidth = 0.45) +
  geom_point(aes(color = endpoint == "any_abnormal"), size = 2.2) +
  scale_color_manual(values = c(`TRUE` = unname(col["rla"]), `FALSE` = unname(col["gray"])), guide = "none") +
  labs(title = "a) Fold-level transportability", x = "Delta vs real-only (percentage points)", y = NULL) +
  theme_pub(9.5) + theme(panel.grid.major.y = element_blank())

sub <- read_csv(file.path(tab_dir, "subgroup_uncertainty.csv"), show_col_types = FALSE)
ecg_sub <- sub %>% filter(dataset == "ecgarr") %>% mutate(subgroup = recode(subgroup, "age=<40" = "Age <40", "age=40-59" = "Age 40-59", "age=60+" = "Age 60+", "sex=F" = "Female", "sex=M" = "Male", "sex=M_age=60+" = "Male age 60+"), subgroup = factor(subgroup, levels = rev(c("Age <40", "Age 40-59", "Age 60+", "Female", "Male", "Male age 60+"))))
p4b <- ggplot(ecg_sub, aes(delta_mean * 100, subgroup)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "#9AA5AD", linewidth = 0.38) +
  geom_errorbar(aes(xmin = delta_ci95_low * 100, xmax = delta_ci95_high * 100), orientation = "y", width = 0.14, color = col["gray"], linewidth = 0.45) +
  geom_point(color = col["rla"], size = 2.0) +
  labs(title = "b) ECG-Arrhythmia subgroup audit", x = "Delta vs real-only (percentage points)", y = NULL) +
  theme_pub(9.5) + theme(panel.grid.major.y = element_blank())

p4c <- ggplot(ecg_sub, aes(harm_lt0 * 100, subgroup)) +
  geom_segment(aes(x = 0, xend = harm_lt0 * 100, yend = subgroup), color = "#DDE4EA", linewidth = 1.2) +
  geom_point(color = col["orange"], size = 2.1) +
  scale_x_continuous(limits = c(0, 7), breaks = c(0, 2, 4, 6), labels = function(x) paste0(x, "%")) +
  labs(title = "c) Subgroup performance-harm audit", x = "Cells with delta < 0", y = NULL) +
  theme_pub(9.5) + theme(panel.grid.major.y = element_blank())

lei <- sub %>% filter(dataset == "leipzig") %>% mutate(subgroup = recode(subgroup, "age=<40" = "Age <40", "sex=F" = "Female", "sex=M" = "Male"), subgroup = factor(subgroup, levels = rev(c("Age <40", "Female", "Male"))))
p4d <- ggplot(lei, aes(delta_mean * 100, subgroup)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "#9AA5AD", linewidth = 0.38) +
  geom_errorbar(aes(xmin = delta_ci95_low * 100, xmax = delta_ci95_high * 100), orientation = "y", width = 0.13, color = col["gray"], linewidth = 0.45) +
  geom_point(color = col["orange"], size = 2.2) +
  geom_text(aes(x = delta_mean * 100 + 0.12, label = paste0("harm ", sprintf("%.1f", harm_lt0 * 100), "%")), hjust = 0, size = 2.55, family = "Arial", color = col["ink"]) +
  scale_x_continuous(limits = c(-1.2, 3.6), breaks = c(-1, 0, 1, 2, 3)) +
  labs(title = "d) Leipzig stress test only", x = "Delta vs real-only (percentage points)", y = NULL) +
  theme_pub(9.5) + theme(panel.grid.major.y = element_blank())

fig4 <- (p4a | p4b) / (p4c | p4d) + plot_layout(widths = c(1.05, 1), guides = "collect") & theme(legend.position = "top")
save_plot(fig4, "Figure4_transportability_subgroup_stress_locked", main_dir, 10, 5.5)

# Supplementary Figure S1: calibration detail.
rel_all <- read_csv(file.path(tab_dir, "primary_any_abnormal_calibration_reliability_summary.csv"), show_col_types = FALSE) %>%
  filter(count > 0) %>%
  mutate(stage_label = recode(stage, raw = "Raw", calibrated = "Source-scaled"), model_label = factor(label_model(model), levels = c("Real-only", "RLA-selected")))
ps1a <- ggplot(rel_all, aes(mean_prob, frac_pos, color = model_label)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "#9AA5AD", linewidth = 0.35) +
  geom_line(linewidth = 0.55) + geom_point(size = 1.2) +
  facet_wrap(~stage_label, nrow = 1) +
  scale_color_manual(values = model_cols) +
  scale_x_continuous(breaks = c(0, 0.5, 1), labels = c("0", "0.50", "1.00")) +
  scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), labels = c("0", "0.25", "0.50", "0.75", "1.00")) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE) +
  labs(title = "a) Reliability curves", x = "Predicted probability", y = "Observed fraction") +
  theme_pub(9.1) +
  theme(
    legend.position = "none",
    panel.spacing.x = unit(1.4, "lines")
  )
cal <- read_csv(file.path(tab_dir, "primary_any_abnormal_calibration_prepost.csv"), show_col_types = FALSE) %>%
  filter(stage %in% c("raw", "calibrated")) %>%
  mutate(stage_label = recode(stage, raw = "Raw", calibrated = "Source-scaled"), model_label = factor(label_model(model), levels = c("Real-only", "RLA-selected")))
ps1b <- cal %>%
  select(fold, model_label, stage_label, brier, ece15, calibration_intercept, calibration_slope) %>%
  pivot_longer(c(brier, ece15, calibration_intercept, calibration_slope), names_to = "metric", values_to = "value") %>%
  mutate(metric = recode(metric, brier = "Brier", ece15 = "ECE15", calibration_intercept = "Intercept", calibration_slope = "Slope")) %>%
  ggplot(aes(stage_label, value, group = interaction(fold, model_label), color = model_label)) +
  geom_line(alpha = 0.35, linewidth = 0.38) + geom_point(size = 1.15, alpha = 0.75) +
  stat_summary(aes(group = model_label), fun = mean, geom = "line", linewidth = 0.8) +
  facet_wrap(~metric, scales = "free_y", nrow = 1) +
  scale_color_manual(values = model_cols) +
  labs(title = "b) Fold-level calibration summaries", x = NULL, y = NULL) +
  theme_pub(9.1) +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 20, hjust = 1)
  )
save_plot((ps1a / ps1b) + plot_layout(heights = c(1.05, 1)), "Supplementary_Figure_S1_calibration_reliability", supp_dir, 9, 6.5)

# Supplementary Figure S2: DCA by endpoint and stage.
dca2 <- read_csv(file.path(tab_dir, "dca_all_endpoints.csv"), show_col_types = FALSE) %>%
  filter(threshold <= 0.50) %>%
  mutate(model_label = factor(label_model(model), levels = c("Review all", "RLA-selected", "Real-only", "Review none")),
         endpoint_label = recode(endpoint, any_abnormal = "Any abnormal", mi = "MI"),
         stage_label = recode(stage, raw = "Raw", calibrated = "Source-scaled"))
ps2 <- ggplot(dca2, aes(threshold * 100, net_benefit, color = model_label, fill = model_label, linetype = model_label)) +
  geom_ribbon(data = dca2 %>% filter(model %in% c("real_only", "rla_selected")), aes(ymin = net_benefit_ci_low, ymax = net_benefit_ci_high), alpha = 0.10, linewidth = 0) +
  geom_line(linewidth = 0.58) +
  facet_grid(endpoint_label ~ stage_label, scales = "free_y") +
  scale_color_manual(values = model_cols) + scale_fill_manual(values = model_cols) +
  scale_linetype_manual(values = c("Review all" = "solid", "RLA-selected" = "solid", "Real-only" = "solid", "Review none" = "dashed")) +
  scale_x_continuous(labels = function(x) paste0(x, "%")) +
  labs(title = "Decision-curve analyses", x = "Threshold probability", y = "Net benefit") +
  theme_pub(9.2)
save_plot(ps2, "Supplementary_Figure_S2_decision_curve_analysis", supp_dir, 9, 6.8)

# Supplementary Figure S3: target-site recalibration sensitivity.
target <- read_csv(file.path(tab_dir, "calibration_target_site_recalibration.csv"), show_col_types = FALSE) %>%
  mutate(stage_label = recode(stage, raw_eval = "Raw", source_temp_eval = "Source-scaled", target_temp_eval = "Target-scaled"),
         model_label = factor(label_model(model), levels = c("Real-only", "RLA-selected")))
ps3 <- target %>%
  select(fold, model_label, stage_label, brier, ece15, temperature_target) %>%
  pivot_longer(c(brier, ece15), names_to = "metric", values_to = "value") %>%
  mutate(metric = recode(metric, brier = "Brier", ece15 = "ECE15"),
         stage_label = factor(stage_label, levels = c("Raw", "Source-scaled", "Target-scaled"))) %>%
  ggplot(aes(stage_label, value, group = interaction(fold, model_label), color = model_label)) +
  geom_line(alpha = 0.35, linewidth = 0.38) + geom_point(size = 1.25) +
  stat_summary(aes(group = model_label), fun = mean, geom = "line", linewidth = 0.9) +
  facet_wrap(~metric, scales = "free_y", nrow = 1) +
  scale_color_manual(values = model_cols) +
  labs(title = "Target-site recalibration sensitivity", x = NULL, y = NULL) +
  theme_pub(9.2) + theme(axis.text.x = element_text(angle = 18, hjust = 1))
save_plot(ps3, "Supplementary_Figure_S3_target_recalibration_sensitivity", supp_dir, 8.8, 4.8)

# Supplementary Figure S4: scarcity and synthetic-pool behavior.
scarcity <- bind_rows(
  read_csv(file.path(tab_dir, "extval_ecgarr_baseline_rla_by_scarcity.csv"), show_col_types = FALSE) %>% mutate(policy = "Certified RLA"),
  read_csv(file.path(tab_dir, "extval_ecgarr_no_cert_by_scarcity.csv"), show_col_types = FALSE) %>% mutate(policy = "Utility-only"),
  read_csv(file.path(tab_dir, "extval_ecgarr_always_aug_r010_by_scarcity.csv"), show_col_types = FALSE) %>% mutate(policy = "Always-on r=0.10")
) %>%
  mutate(policy = factor(policy, levels = c("Certified RLA", "Utility-only", "Always-on r=0.10")),
         scarcity_label = factor(case_when(scarcity == 0 ~ "Min\n200", scarcity == 0.25 ~ "25%\n3700", scarcity == 0.5 ~ "50%\n7401", TRUE ~ "Full\n14803"), levels = c("Min\n200", "25%\n3700", "50%\n7401", "Full\n14803")))
ps4a <- ggplot(scarcity, aes(scarcity_label, deploy_rate * 100, color = policy, group = policy)) + geom_line(linewidth = 0.65) + geom_point(size = 1.8) + scale_color_manual(values = policy_cols) + labs(title = "a) Selection rate", x = "Source-label availability", y = "Cells authorized (%)") + theme_pub(9.1)
ps4b <- ggplot(scarcity, aes(scarcity_label, mean_delta * 100, color = policy, group = policy)) + geom_hline(yintercept = 0, linetype = "dashed", color = "#9AA5AD", linewidth = 0.35) + geom_line(linewidth = 0.65) + geom_point(size = 1.8) + scale_color_manual(values = policy_cols) + labs(title = "b) Mean external delta", x = "Source-label availability", y = "Macro-AUPRC delta (p.p.)") + theme_pub(9.1)
ps4c <- ggplot(scarcity, aes(scarcity_label, harm_lt0 * 100, color = policy, group = policy)) + geom_line(linewidth = 0.65) + geom_point(size = 1.8) + scale_color_manual(values = policy_cols) + labs(title = "c) Performance-harm rate", x = "Source-label availability", y = "Cells with delta < 0 (%)") + theme_pub(9.1)
pool <- bind_rows(
  read_csv(file.path(tab_dir, "extval_ecgarr_baseline_rla_by_pool_tag.csv"), show_col_types = FALSE) %>% mutate(policy = "Certified RLA"),
  read_csv(file.path(tab_dir, "extval_ecgarr_no_cert_by_pool_tag.csv"), show_col_types = FALSE) %>% mutate(policy = "Utility-only"),
  read_csv(file.path(tab_dir, "extval_ecgarr_always_aug_r010_by_pool_tag.csv"), show_col_types = FALSE) %>% mutate(policy = "Always-on r=0.10")
) %>% mutate(policy = factor(policy, levels = c("Certified RLA", "Utility-only", "Always-on r=0.10")))
top_pool <- pool %>% group_by(pool_tag) %>% summarize(max_abs = max(abs(mean_delta)), .groups = "drop") %>% arrange(desc(max_abs)) %>% slice_head(n = 10)
ps4d <- pool %>% filter(pool_tag %in% top_pool$pool_tag) %>%
  mutate(pool_tag = factor(pool_tag, levels = rev(top_pool$pool_tag))) %>%
  ggplot(aes(policy, pool_tag, fill = mean_delta * 100)) +
  geom_tile(color = "white", linewidth = 0.35) +
  scale_fill_gradient2(low = col["fixed"], mid = "white", high = col["utility"], midpoint = 0, name = "Delta (p.p.)") +
  labs(title = "d) Synthetic-pool condition", x = NULL, y = NULL) +
  theme_pub(8.9) + theme(axis.text.x = element_text(angle = 18, hjust = 1))
save_plot((ps4a | ps4b) / (ps4c | ps4d) + plot_layout(guides = "collect") & theme(legend.position = "top"), "Supplementary_Figure_S4_scarcity_pool_behavior", supp_dir, 9.5, 6.8)

# Supplementary Figure S5: subgroup and stress detail.
het <- read_csv(file.path(tab_dir, "subgroup_heterogeneity.csv"), show_col_types = FALSE) %>% filter(dataset == "ecgarr") %>% mutate(contrast = recode(contrast, "age=40-59_vs_age=60+" = "Age 40-59 vs 60+", "age=<40_vs_age=40-59" = "Age <40 vs 40-59", "age=<40_vs_age=60+" = "Age <40 vs 60+", "sex_M_vs_F" = "Male vs female"))
ps5a <- p4b + labs(title = "a) ECG-Arrhythmia subgroup deltas")
ps5b <- p4d + labs(title = "b) Leipzig stress-test deltas")
ps5c <- ggplot(het, aes(delta_diff_mean * 100, reorder(contrast, delta_diff_mean))) +
  geom_vline(xintercept = 0, color = "#9AA5AD", linetype = "dashed", linewidth = 0.35) +
  geom_col(fill = col["rla"], width = 0.55, alpha = 0.88) +
  geom_text(aes(label = paste0("p=", formatC(p_perm_two_sided, format = "f", digits = 3))), hjust = if_else(het$delta_diff_mean >= 0, -0.08, 1.08), size = 2.6, family = "Arial") +
  scale_x_continuous(limits = c(-0.25, 0.35)) +
  labs(title = "c) Permutation contrasts", x = "Contrast in mean delta (p.p.)", y = NULL) +
  theme_pub(9.1) + theme(panel.grid.major.y = element_blank())
ps5d <- ggplot() +
  annotate("text", x = 0, y = 0.72, label = "Interpretation", fontface = "bold", family = "Arial", size = 4.0, color = col["ink"]) +
  annotate("text", x = 0, y = 0.42, label = "Subgroup analyses use available metadata only.\nLeipzig is an out-of-distribution stress test.\nThese panels audit heterogeneity; they do not prove fairness\nor validate pediatric/congenital-heart-disease deployment.", family = "Arial", size = 3.15, lineheight = 1.08, color = col["ink"]) +
  xlim(-1, 1) + ylim(0, 1) + theme_void()
save_plot((ps5a | ps5b) / (ps5c | ps5d), "Supplementary_Figure_S5_subgroup_stress_detail", supp_dir, 9.5, 6.8)

# Supplementary Figure S6: certification diagnostics.
master <- read_csv(file.path(tab_dir, "extval_ecgarr_baseline_rla_master.csv.gz"), show_col_types = FALSE) %>%
  mutate(ratio_label = if_else(ratio == 0, "Fail closed", paste0("r=", ratio)),
         selected_positive = ratio > 0)
ps6a <- master %>% count(ratio_label) %>% mutate(ratio_label = factor(ratio_label, levels = c("Fail closed", "r=0.05", "r=0.1", "r=0.2"))) %>%
  ggplot(aes(ratio_label, n, fill = ratio_label)) + geom_col(width = 0.62) + geom_text(aes(label = n), vjust = -0.3, size = 2.8, family = "Arial") +
  scale_fill_manual(values = c("Fail closed" = "#B8BDC2", "r=0.05" = unname(col["utility"]), "r=0.1" = unname(col["rla"]), "r=0.2" = unname(col["fixed"]))) +
  labs(title = "a) Certified RLA decisions", x = NULL, y = "Report cells") + theme_pub(9.1) + theme(legend.position = "none")
ps6b <- master %>% filter(selected_positive, is.finite(lb_delta_cert_vs_real_only), is.finite(delta_util_vs_real_only)) %>%
  ggplot(aes(delta_util_vs_real_only * 100, lb_delta_cert_vs_real_only * 100, color = ratio_label)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#9AA5AD", linewidth = 0.35) + geom_vline(xintercept = 0.2, linetype = "dashed", color = "#9AA5AD", linewidth = 0.35) +
  geom_point(alpha = 0.72, size = 1.45) +
  scale_color_manual(values = c("r=0.05" = unname(col["utility"]), "r=0.1" = unname(col["rla"]), "r=0.2" = unname(col["fixed"]))) +
  labs(title = "b) Utility and certification gates", x = "UTIL delta (p.p.)", y = "CERT lower bound (p.p.)") + theme_pub(9.1) + theme(legend.position = "none")
ps6c <- master %>% filter(selected_positive) %>% mutate(ratio_label = factor(ratio_label, levels = c("r=0.05", "r=0.1", "r=0.2"))) %>%
  ggplot(aes(ratio_label, delta * 100, color = ratio_label, fill = ratio_label)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#9AA5AD", linewidth = 0.35) +
  geom_boxplot(width = 0.45, alpha = 0.10, outlier.shape = NA, linewidth = 0.42) +
  geom_jitter(width = 0.11, alpha = 0.45, size = 0.75) +
  scale_color_manual(values = c("r=0.05" = unname(col["utility"]), "r=0.1" = unname(col["rla"]), "r=0.2" = unname(col["fixed"]))) +
  scale_fill_manual(values = c("r=0.05" = unname(col["utility"]), "r=0.1" = unname(col["rla"]), "r=0.2" = unname(col["fixed"]))) +
  labs(title = "c) External delta after authorization", x = "Selected ratio", y = "Macro-AUPRC delta (p.p.)") + theme_pub(9.1) + theme(legend.position = "none")
ps6d <- scarcity %>% filter(policy == "Certified RLA") %>% ggplot(aes(scarcity_label, deploy_rate * 100)) + geom_col(fill = col["rla"], width = 0.58, alpha = 0.9) + labs(title = "d) Authorization by label availability", x = "Source-label availability", y = "Cells authorized (%)") + theme_pub(9.1)
save_plot((ps6a | ps6b) / (ps6c | ps6d), "Supplementary_Figure_S6_certification_diagnostics", supp_dir, 9.5, 6.8)

dir.create(file.path(root, "metadata"), recursive = TRUE, showWarnings = FALSE)
writeLines(c(
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "Figure 1 copied from user schematic source.",
  "Figures 2-4 and Supplementary Figures S1-S6 regenerated in R with ggplot2 and ggprism.",
  paste0("Primary manifest: 1170d044a59e4c26da0b21433d06e240c04c67ca3fc320857de7382153335e12"),
  paste0("Secondary manifest: ", unique(read_csv(file.path(multi_dir, "secondary_policy_overall_bootstrap.csv"), show_col_types = FALSE)$policy_manifest_sha256))
), file.path(root, "metadata", "BUILD_QA_R_GGPRISM_FULL_SET.txt"))

message("Completed full R/ggprism figure set at: ", root)

