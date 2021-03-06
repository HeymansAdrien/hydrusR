% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_alevel_out.R
\name{read.alevel.out}
\alias{read.alevel.out}
\title{Read outputs of ALEVEL.OUT}
\usage{
read.alevel.out(project.path, out.file = "A_Level.out", output = NULL,
  warn = FALSE, ...)
}
\arguments{
\item{project.path}{path of hydrus project}

\item{out.file}{name of teh alevel file: "A_Level.out" is default output file.}

\item{output}{vector of output names that should be read}

\item{warn}{Logical for displaying/suppressing warnings producted by data.table::fread()}

\item{...}{}
}
\description{
Read outputs of ALEVEL.OUT
}
