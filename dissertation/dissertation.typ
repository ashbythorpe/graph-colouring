// =============================================================================
// University of Bristol — School of Computer Science
// Dissertation Template (Typst port of dissertation.cls + DissertationTemplate.tex)
//
// Usage: fill in the variables in the CONFIGURATION section below, then
// write your chapters.  Delete or comment out any front-matter sections
// that do not apply to your submission.
// =============================================================================

#import "@preview/theoretic:0.3.1"
#import theoretic.presets.basic: * // this will automatically load predefined styled environments
#show ref: theoretic.show-ref      // this is necessary for references to theorems to work

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURATION  ← change these fields
// ─────────────────────────────────────────────────────────────────────────────

#let cfg = (
  author: "Ashby Thorpe",
  supervisor: "Dr. Christian Konrad", // Title + First + Last
  degree: "BSc", // BSc | MEng | MSci | MSc | PhD
  unit: "COMS30044", // COMS30044 | COMS30045 | COMSM0052 | COMSM0142
  title: "Asymmetric Palette Sparsification",
  subtitle: "In Practice",
  year: "2025",
)

// ─────────────────────────────────────────────────────────────────────────────
// HELPER LOOK-UPS (mirrors the \IfEqCase blocks in the .cls)
// ─────────────────────────────────────────────────────────────────────────────

#let degree-name = (
  BSc: "Bachelor of Science",
  MEng: "Master of Engineering",
  MSci: "Master of Science",
  MSc: "Master of Science",
  PhD: "Doctor of Philosophy",
).at(cfg.degree, default: cfg.degree)

#let unit-cp = (
  COMS30044: "20CP",
  COMS30045: "40CP",
  COMSM0052: "40CP",
  COMSM0142: "40CP",
).at(cfg.unit, default: "40CP")

// ─────────────────────────────────────────────────────────────────────────────
// PAGE GEOMETRY & FONTS  (mirrors geometry + fancyhdr in .cls)
// ─────────────────────────────────────────────────────────────────────────────

#set page(
  paper: "a4",
  margin: (left: 2.5cm, right: 2.5cm, top: 2.5cm, bottom: 2.5cm),
  header: context {
    // No header on the very first page of each chapter
    if counter(page).get().first() == 1 { return }
    set text(style: "italic", size: 9pt)
    grid(
      columns: (1fr, 1fr),
      // align(left, counter(heading).display()), align(right, []),
      // right-side mark (chapter title) could be added here
    )
    line(length: 100%, stroke: 0.5pt)
  },
  footer: context {
    line(length: 100%, stroke: 0.5pt)
    v(-4pt)
    align(center, counter(page).display())
  },
  numbering: "1",
)

#set text(font: "New Computer Modern", size: 10pt)
#set par(justify: true, leading: 0.65em)
// #show raw: set text(font: "New Computer Modern Mono")

// Headings
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(1cm)
  if counter(heading).get().first() > 0 {
    text(size: 17pt, weight: "bold")[Chapter #counter(heading).display()]
    v(0.3cm)
  }
  text(size: 24pt, weight: "bold")[#it.body]
  v(0.5cm)
}
#show heading.where(level: 2): it => {
  v(0.6cm)
  text(size: 13pt, weight: "bold")[#counter(heading).display() #h(1em) #it.body]
  v(0.3cm)
}
#show heading.where(level: 3): it => {
  v(0.4cm)
  text(size: 11pt, weight: "bold")[#counter(heading).display() #h(1em) #it.body]
  v(0.2cm)
}

// ─────────────────────────────────────────────────────────────────────────────
// TITLE PAGE  (mirrors \maketitle in dissertation.cls)
// ─────────────────────────────────────────────────────────────────────────────

#page(numbering: none, header: none, footer: none)[
  #align(center)[
    // Replace the image path with your actual UoB logo file if available.
    #image("UoB_CMYK_24.pdf", width: 35%)
    #text(size: 14pt, weight: "bold")[
      UNIVERSITY OF BRISTOL \
      SCHOOL OF COMPUTER SCIENCE
    ]
    #v(2cm)
    #text(size: 20pt, weight: "bold")[#cfg.title]
    #if cfg.subtitle != "" {
      v(0.5cm)
      text(size: 15pt)[#cfg.subtitle]
    }
    #v(1cm)
    #text(size: 14pt)[#cfg.author]
    #v(1cm)
    #line(length: 50%, stroke: 0.5pt)
    #v(1cm)
    #text(size: 11pt)[
      A dissertation submitted to the University of Bristol \
      in accordance with the requirements of the degree of \
      *#degree-name* in the Faculty of Engineering \
      *worth #unit-cp*.
    ]
    #v(1cm)
    #line(length: 50%, stroke: 0.5pt)
    #v(1cm)
    #text(size: 11pt)[#cfg.year]
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
// FRONT MATTER  (Roman numerals)
// ─────────────────────────────────────────────────────────────────────────────

#set page(numbering: "i")
#counter(page).update(1)
#set heading(outlined: false)

// ── Abstract ─────────────────────────────────────────────────────────────────
= Abstract
<chap:abstract>

We consider two sublinear graph colouring algorithms: the Asymmetric Palette
Sparsification (APS) Algorithm proposed by Assadi and Yazdanyar @Assadi_2026,
and an algorithm using graph partitioning. We show that on real graphs, while
both algorithms find good quality colourings using less memory than the greedy
algorithm, the graph partitioning algorithm is able to find smaller colourings
while storing fewer edges than the APS algorithm.

// ── Dedication & Acknowledgements ────────────────────────────────────────────
= Dedication and Acknowledgements
<chap:acknowledgements>

#v(0.5cm)

I'd like to thank my supervisor, Christian Konrad, for his continued enthusiasm
and support throughout this project.

// ── Declaration ──────────────────────────────────────────────────────────────
= Declaration
<chap:declaration>

I declare that the work in this dissertation was carried out in accordance
with the requirements of the University's Regulations and Code of Practice for
Taught Programmes and that it has not been submitted for any other academic
award. Except where indicated by specific reference in the text, this work is
my own work. Work done in collaboration with, or with the assistance of others
including AI methods, is indicated as such. I have identified all material in
this dissertation which is not my own work through appropriate referencing and
acknowledgement. Where I have quoted or otherwise incorporated material which
is the work of others, I have included the source in the references. Any views
expressed in the dissertation, other than referenced material, are those of the
author.

#v(3cm)
#cfg.author, #cfg.year

// ── AI Declaration ───────────────────────────────────────────────────────────
= AI Declaration
<chap:ai-declaration>

I declare that any and all AI usage within the project has been recorded and
noted within Appendix A or within the main body of the text itself. This
includes (but is not limited to) usage of text generation methods incl. LLMs,
text summarisation methods, or image generation methods.

I understand that failing to divulge use of AI within my work counts as
contract cheating and can result in a zero mark for the dissertation or even
requiring me to withdraw from the University.

#v(3cm)
#cfg.author, #cfg.year

// ── Table of Contents ────────────────────────────────────────────────────────
#{
  show outline.entry.where(level: 1): it => {
    strong(it)
  }
  outline(
    title: [Table of Contents],
    depth: 2,
    indent: auto,
  )
}

// ── List of Figures ──────────────────────────────────────────────────────────
#outline(
  title: [List of Figures],
  target: figure.where(kind: image),
)

// ── List of Tables ───────────────────────────────────────────────────────────
#outline(
  title: [List of Tables],
  target: figure.where(kind: table),
)

// ── Ethics Statement ─────────────────────────────────────────────────────────
= Ethics Statement
<chap:ethics>

This project did not require ethical review, as determined by my supervisor,
Christian Konrad.

// ── Summary of Changes ───────────────────────────────────────────────────────
// = Summary of Changes
// <chap:changes>
//
// #text(weight: "bold")[Compulsory only if the dissertation is a resubmission, otherwise delete]
// #v(0.5cm)
//
// If and only if the dissertation represents a resubmission (e.g., as the result
// of a resit), this section is compulsory: the content should summarise all
// non-trivial changes made to the initial submission.

// ── Supporting Technologies ──────────────────────────────────────────────────
= Supporting Technologies
<chap:tech>

- All algorithms were written in C++, and compiled using gcc.
- The Boost Graph Library was used to compare against my custom implementations.
- Python and the Optuna library were used to gather data.
- Data analysis and plotting were done in R, using the following libraries:
  dplyr, purrr, forcats, ggplot2, patchwork.

// ── Notation and Acronyms ────────────────────────────────────────────────────
// = Notation and Acronyms
// <chap:notation>
//
// Any well written document will introduce notation and acronyms before their
// use, even if they are standard in some way.
//
// #table(
//   columns: (auto, auto, 1fr),
//   stroke: none,
//   [AES], [:], [Advanced Encryption Standard],
//   [DES], [:], [Data Encryption Standard],
//   [...], [...], [...],
// )

// ─────────────────────────────────────────────────────────────────────────────
// MAIN MATTER  (Arabic numerals, chapter counter resets)
// ─────────────────────────────────────────────────────────────────────────────

#set page(numbering: "1")
#counter(page).update(1)
#set heading(numbering: "1.1", outlined: true)
#counter(heading).update(0)

#let wideemptyset = text(features: ("cv01",), $emptyset$)

// ── Chapter 1: Introduction ───────────────────────────────────────────────────
= Introduction
<chap:introduction>

Over the last few decades, the modern world has seen the rise of big data:
massive, unstructured datasets that are beyond the means of normal software to
process and analyse. In the realm of graphs, this problem is exemplified -
consider the large social networks of Facebook or Twitter, containing billions
of nodes @facebookscale; or a graph to model the human brain,
which would require representing over 100 trillion synapses
@zhang2019basicneuralunitsbrain. Such graphs cannot fit into the main memory of
a single computer in their entirety, and so must be processed using alternative
methods.

One approach to handling big data is the _data stream model_, where
algorithms must process its input as a stream of data, and are restricted
to some _sublinear_ amount of memory, preventing them from storing the entire
stream @datastream. Such algorithms are ideal when dealing with big data, since
they are often able to handle large inputs while using significantly less
memory than traditional algorithms.

_Graph colouring_ is a fundamental problem in graph theory. Let $G = (V, E)$
be an $n$-vertex graph with maximum degree $Delta$. A _$k$-colouring_ is a
function $phi: V -> [k]$ such that for every $(u, v) in E$, $phi(u) != phi(v)$.
In other words, we assign a colour to every vertex so that no two adjacent
vertices have the same colour. Graph colouring enjoys many applications,
including scheduling @graphcoloringscheduling, register allocation
@graphcoloringregisterallocation and Sudoku @graphcoloringsudoku.
// TODO: could maybe discuss why it is interesting theoretically also

Over the last two decades, most of the work on graph streams has focused on the
_semi-streaming_ model, where the input is processed as a stream of edges, and
the algorithm must use only $tilde(O)(n)$ space
#footnote[We use $tilde(O)(n) := O(n "polylog" n)$.]
@semistreaming (semi-streaming is so-called because the space usage is only
sublinear in the number of edges, not the number of nodes). This allows
algorithms to store all the vertices of a graph, but not all of its edges;
graphs can contain up to $n (n - 1)$ edges in total.

One classical graph colouring algorithm is the greedy algorithm, which iterates
through vertices, assigning each vertex the smallest colour that has not been
assigned to its neighbours. This runs in linear time, and guarantees a $(Delta
+ 1)$-colouring. However, it requires access to the full set of neighbours of
each vertex, making it unsuitable as a semi-streaming algorithm.

One idea to reduce the number of edges stored is to introduce certain
restrictions on the colours that each vertex can take, with the aim of making
certain edges "redundant" (since they don't affect the resulting colouring).

One way of doing this is _Palette Sparsification_, introduced by Assadi,
Chen and Kanna @assadi_2019. The idea here is to assign each vertex a small,
randomly chosen subset of colours (a _palette_), and to find a colouring of $G$
so that every vertex only uses the colours from its palette. This allows the
algorithm to ignore edges between vertices whose palettes do not overlap
("sparsifying" the graph).

Another approach uses _graph partitioning_ (see e.g.
@alon2020palettesparsification @andoni2014parallelalgorithmsgeometricgraph
@greedymapreducestreaming) - the idea is to randomly partition the vertices
into several subsets, and colour the induced subgraphs separately - the
algorithm can then ignore edges between vertices in different partitions.

== Background

In 2018, Assadi, Chen and Khanna @assadi_2019 proved the following:

#theorem(<thm:pst>)[Palette Sparsification Theorem @assadi_2019][
  Let $G = (V, E)$ be an $n$-vertex graph with maximum degree $Delta$. Suppose
  for any vertex $v in V$, we sample $O(log n)$ colours $L(v)$ from ${1, ...,
    Delta + 1}$ independently and uniformly at random. Then with high probability
  there exists a proper $(Delta + 1)$-colouring of $G$ in which the colour for
  every vertex $v$ is chosen from $L(v)$.
]

With this, we can construct a simple semi-streaming algorithm:

+ For every vertex $v in V$, sample $L(v)$.
+ During the stream, only store edges $(u, v)$ such that $L(u) inter L(v) !=
  wideemptyset$.
+ Use @thm:pst[-] to colour the resulting graph.

In 2025, Assadi and Yazdanyar @Assadi_2026 went on to prove the following:

#theorem(<thm:apst>)[Asymmetric Palette Sparsification Theorem @Assadi_2026][
  For any graph $G = (V, E)$ with maximum degree $Delta$, there is a
  distribution on list-sizes $ell: V -> NN$ (depending only on vertices $V$ and
  not edges $E$) such that an average list size is $O(log^2 (n))$ and the
  following holds. With high probability, if we sample $ell(v)$ colours $L(v)$
  for each vertex $v in V$ independently and uniformly at random from colours
  ${1, 2, ..., Delta + 1}$, then, with high probability, the greedy colouring
  algorithm that processes vertices in some fixed order (determined by vertex
  degrees and list sizes) finds a proper colouring of $G$ by colouring each $v$
  from its own list $L(v)$.
]

With this, we can improve upon our previous algorithm, by sampling $L(v)$ using
this new method. The advantage of this is the resulting graph can be coloured
_greedily_, making the algorithm much simpler.

== Our contributions

We present a thorough comparison of the greedy algorithm, the Asymmetric
Palette Sparsification (APS) algorithm, and the graph-partitioning algorithm.

#cite(<Assadi_2026>, form: "prose") only prove an $tilde(O)(n)$ space bound
on the APS bound in expectation. In @sec:algorithms, we find high probability
$tilde(O)(n)$ memory bounds on both the APS algorithm and the
graph-partitioning algorithm. We also present a counterexample to show that the
graph-partitioning algorithm is unable to find $(Delta + 1)$-colourings for
every graph (with high probability) - showing that the APS algorithm performs
better theoretically.

In @sec:implementations, we describe high-performance implementations of
the greedy algorithm, the APS algorithm, and the graph-partitioning algorithm.
We find that many changes are required for the APS algorithm to perform well
in practice. We find that, even on very large graphs, the default list size
formula assigns each vertex a much too large palette, resulting in almost no
edges being skipped; as a result, we introduce a custom list size formula.
We introduce a palette compression technique to reduce the memory cost of
storing each vertex's palette. Finally, we find that randomly permuting the
vertices of the APS algorithm and randomly sampling the partitions of the
graph-partitioning algorithm offer no benefit on real, non-adversarial graphs.

The resulting APS and graph-partitioning implementations gain a number of
parameters, which offer a tradeoff between colouring size and memory use. In
@sec:experiments, we analyse the performance of the three algorithms across
their parameter space on a selection of real-world graph datasets.

We find that:

- On a subset of the graphs we tested on, the APS algorithm is able to produce
  colourings of a similar size to the greedy algorithm, while using less
  memory.
- On all the graphs we tested on, the partitioning algorithm is able to produce
  similarly sized colourings to the greedy algorithm, while using significantly
  less memory and often less time as well. The algorithm performs better - in
  terms of its colouring size to memory use tradeoff - than the APS algorithm
  on all graphs.

= Preliminaries

== Notation

For an integer $n >= 1$, define $[n] := {1, 2, ..., n}$. For a graph
$G = (V, E)$ and a vertex $v in V$, we use $N(v)$ for the neighbours of $v$,
and $deg(v)$ for its degree. For $U subset.eq V$, we use $G[U]$ for the induced
subgraph. Unless otherwise stated, $n$ will be the number of vertices in $G$,
and $Delta$ will be its maximum degree.

We say an event happens *with high probability* if it happens with probability
$1 - frac(1, "poly"(n), style: "horizontal")$.

A *semi-streaming* algorithm is one where the edges of a graph $G = (V, E)$
are presented to the algorithm in a (potentially adversarial) sequence, and
the algorithm must present a solution to the problem at the end of the stream,
while only using $tilde(O)(n)$ space.

== Chernoff bounds

It is useful to be able to provide an upper bound on the probability that a
random variable deviates from its expected value by some amount, usually with
the aim of showing that this deviation does not happen with high probability.
Such a bound is called a concentration inequality, and while we omit common
such inequalities (e.g. Markov's inequality), we state and prove some other
useful bounds.

We follow the proofs of #cite(<janson2000random>, form: "prose").

#definition[
  A *Chernoff bound* for a random variable $X$ is a concentration inequality
  obtained by applying Markov's inequality to $e^(u X)$ (for some $u in RR$).

  For $u >= 0$, we obtain the following for all $a in RR$:

  $ Pr(X >= a) = Pr(e^(u X) >= e^(u a)) <= EE[e^(u X)] e^(-u a). $

  Similarly, for $u <= 0$:

  $ Pr(X <= a) = Pr(e^(u X) >= e^(u a)) <= EE[e^(u X)] e^(-u a). $

  For a specific random variable, we often substitute an explicit form for the
  moment generating function $EE[e^(u X)]$, and then find the value of $u$ that
  minimises the resulting expression.
]

#proposition(<prop:chernoff>)[Adapted from @janson2000random[~Theorem 2.1]][
  Let $X ~ B(n, p)$. Then for $t >= 0$:

  $
    & Pr(X <= EE[X] - t) <= exp(- (t^2) / (2 EE[X])), \
    & Pr(X >= EE[X] + t) <= exp(- (t^2) / (2 (EE[X] + frac(t, 3, style: "horizontal")))).
  $
]

#proof[
  We apply the Chernoff bound to $X$: for all $u >= 0$

  $
    Pr(X <= EE[X] - t) <= EE[e^(u X)] e^(-u (EE[X] - t))
    = (1 - p + p e^u)^n e^(-u (EE[X] - t)).
  $

  For $t <= EE[X]$ (when $t > EE[X]$, the probability is 0, and the bound
  holds), we choose $u$ such that

  $ e^u = ((EE[X] - t) (1 - p)) / (p (n - EE[X] + t)). $

  So, since $EE[X] = n p$,

  $
    Pr(X <= EE[X] - t) & <=
    ((p (n - EE[X] + t)) / ((EE[X] - t) (1 - p)))^(EE[X] - t) (1 - p + ((EE[X] - t) (1 - p)) / (n - EE[X] + t))^n \
    & <= (EE[X] / (EE[X] - t))^(EE[X] - t) ((n - EE[X]) / (n - EE[X] + t))^(n + EE[X] - t) \
    & = exp((EE[X] - t) ln(EE[X] / (EE[X] - t)) + (n - EE[X] + t) ln ((n - EE[X]) / (n - EE[X] + t)) + t - t).
  $

  Define, for $x >= -1$, $phi(x) := (1 + x) ln(1 + x) - x$. Then we can
  rewrite the previous expression as

  $
    Pr(X <= EE[X] - t) & <= exp(- EE[X] phi((-t) / EE[X]) - (n - EE[X]) phi(t / (n - EE[X]))) \
                       & <= exp(- EE[X] phi((-t) / EE[X])).
  $

  Note that since $phi(0) = 0$ and $phi'(x) = ln(1 + x) < x$,
  $phi(x) >= frac(x^2, 2, style: "horizontal")$ for $-1 <= x <= 0$, and so

  $ Pr(X <= EE[X] - t) <= exp(- (t^2) / (2 EE[X])). $

  By a similar argument, for $t <= n - k$ (again, when $t > n - k$,
  $Pr(X >= EE[X] + t)$ is 0 and so the bound holds) we get:

  $
    Pr(X >= EE[X] + t) <= exp(- EE[X] phi(t / EE[X])).
  $

  Note that $phi(0) = phi'(0) = 0$, and since for $x >= -1$, $(1 + x) <= (1 +
    frac(x, 3, style: "horizontal"))^3$,

  $
    phi''(x) = 1/(1 + x) >= 1 / (1 + frac(x, 3, style: "horizontal"))^3 = ((x^2) / (2 (1 + frac(x, 3, style: "horizontal"))))''.
  $

  Therefore,

  $ phi(x) >= (x^2) / (2 (1 + frac(x, 3, style: "horizontal"))). $

  This gives us:

  $
    Pr(X <= EE[X] + t) <= exp(- (t^2) / (2 (EE[X] + frac(t, 3, style: "horizontal")))).
  $
]

#proposition(<prop:bernchernoff>)[Adapted from @janson2000random[~Theorem 2.8]][
  Let $X = sum_(i = 1)^n X_i$ for $X_i ~ "Be"(p_i)$ independent. Then for
  $t >= 0$

  $ Pr(X >= EE[X] + t) <= exp(- (t^2) / (2 (EE[X] + frac(t, 3, style: "horizontal")))). $
]

#proof[
  Let $Y ~ B(n, frac(EE[X], n, style: "horizontal"))$ with $EE[X] = sum_(i = 1)^n p_i$.

  So, for all $u in RR$:

  $
    EE[e^(u X)] = product_(i = 1)^n EE[e^(u X_i)] = product_(i = 1)^n (1 + p_i (e^u - 1)).
  $

  Taking the logarithm, and using Jensen's inequality:

  $
    ln (product_(i = 1)^n (1 + p_i (e^u - 1))) & = sum_(i = 1)^n ln(1 + p_i (e^u - 1)) \
                                               & <= sum_(i = 1)^n ln(1 + (sum_(i = 1)^n p_i) / n (e^u - 1))
                                                 = ln (product_(i = 1)^n (1 + EE[X] / n (e^u - 1))).
  $

  And so:

  $
    EE[e^(u X)] <= product_(i = 1)^n (1 + EE[X] / n (e^u - 1))
    = EE[e^(u Y)].
  $

  Applying the Chernoff bound to $X$, for all $u >= 0, t >= 0$:

  $
    Pr(X >= EE[X] + t) <= EE[e^(u X)] e^(-u (EE[X] + t))
    <= EE[e^(u Y)] e^(-u (EE[Y] + t)).
  $

  Therefore, we can use the bound proved in @prop:chernoff[-]:

  $
    Pr(X >= EE[X] + t) <= exp(- (t^2) / (2 (EE[X] + frac(t, 3, style: "horizontal")))).
  $
]

#definition[
  A *hypergeometric distribution*, with parameters $N$, $K$ and $n$, is the
  distribution of a discrete random variable $X$, defined as the number of
  “good” elements selected when sampling $n$ elements _without replacement_
  from a set of size $N$ containing exactly $K$ “good” elements.

  The hypergeometric distribution is similar to the binomial distribution,
  except the binomial distribution samples with replacement. Much like a
  binomial random variable, a hypergeometric random variable can be viewed as
  the sum of $n$ _dependent_ indicator variables, each representing the $i$th
  sample.
]

#proposition(<prop:hypergeometric>)[Adapted from @janson2000random[~Theorem 2.10]][
  Let $X ~ "Hypergeometric"(N, K, n)$. Then for all $t >= 0$

  $
    Pr(X <= EE[X] - t) <= exp(-(t^2) / (2 EE[X])), \
    Pr(X >= EE[X] + t) <= exp(- (t^2) / (2 (EE[Y] + frac(t, 3, style: "horizontal")))) = exp(- (t^2) / (2 (EE[X] + frac(t, 3, style: "horizontal")))).
  $
]

#proof[
  Let $Y ~ B(n, frac(K, N, style: "horizontal"))$ (note then that
  $EE[X] = EE[Y]$). Since $e^x$ is convex @hoeffding[Theorem 4], we have that
  for all $u in RR$,

  $ EE[e^(u X)] <= EE[e^(u Y)]. $

  So, applying the Chernoff bound to $X$, for all $u <= 0, t >= 0$,

  $
    Pr(X <= EE[X] - t)
    <= e^(-u(EE[X] - t)) EE[e^(u X)]
    <= e^(- u (EE[Y] - t)) EE[e^(u Y)].
  $

  Therefore, we can use the bounds proved in @prop:chernoff[-].

  $
    Pr(X <= EE[X] - t) <= exp(- (t^2) / (2 EE[Y])) = exp(- (t^2) / (2 EE[X])). \
    Pr(X >= EE[X] + t) <= exp(- (t^2) / (2 (EE[Y] + frac(t, 3, style: "horizontal")))) = exp(- (t^2) / (2 (EE[X] + frac(t, 3, style: "horizontal")))).
  $
]

== Negative Association

We introduce a concept known as _Negative Association_ (NA). Negative
Association can be viewed as a similar but stronger property than negative
correlation/covariance for a collection of random variables $X_1, X_2, ...,
X_n$. Intuitively, if a collection of variables are NA, then if a subset of
them are higher than their expected values, then another subset must be lower
than their expected values.

#definition[@negativeassociation[~Definition 2.1]][
  A collection of random variables $X_1, ..., X_n$ are said to be *negatively
  associated* (NA) if for every disjoint subsets $I, J subset.eq [n]$, and
  any two monotone increasing functions $f$ and $g$,

  $ "Cov"(f((X_i)_(i in I)), g((X_j)_(j in J))) <= 0. $
]

We state a few useful properties of NA variables.

#proposition(
  <prop:marginalbounds>,
)[@Wajc2017NegativeA[~Corollary 3]][
  For any NA variables $X_1, ..., X_n$ and real values $x_1, ..., x_n$,

  $
    Pr(and.big_i X_i >= x_i) <= product_i Pr(X_i >= x_i) quad "and" quad
    Pr(and.big_i X_i <= x_i) <= product_i Pr(X_i <= x_i).
  $
]

#proposition(<prop:nafunctions>)[@Wajc2017NegativeA[~Corollary 4]][
  Let $X_1, ..., X_n$ be NA random variables. Then, for disjoint subsets $I_1,
  ..., I_k subset.eq [k]$, and for every set of $k$ positive monotone
  increasing functions $f_1, ..., f_k$, it holds:

  $ EE[product_i f_(i)((X_j)_(j in I_i))] <= product_k EE[f_(i)((X_j)_(j in I_i))]. $
]

#proposition(<prop:permutationna>)[@Wajc2017NegativeA[~Lemma 8]][
  Let $x_1 <= x_2 <= ... <= x_n$ be $n$ values, and let $X_1, X_2, ..., X_n$ be
  random variables such that ${X_1, ..., X_n} = {x_1, ..., x_n}$ always, with
  all possible assignments equally likely (a permutation distribution). Then
  $X_1, X_2, ..., X_n$ are NA.
]

#proposition(<prop:naclosure>)[@Wajc2017NegativeA[~Lemma 9]][
  Suppose $f_1, f_2, ..., f_k : RR^n → RR$ are all monotonically increasing or
  all monotone decreasing, with each $f_i$ depending on disjoint subsets of
  $[n]$, $S_1, S_2, ..., S_k subset.eq [n]$. In that case, if $X_1, X_2, ...,
  X_n$ are NA, then with $arrow(X) := (X_1, ..., X_n)$, the set of random
  variables $Y_1 = f_1(arrow(X)), Y_2 = f_2(arrow(X)), ..., Y_k
  = f_(k)(arrow(X))$ are NA.
]

#definition[
  A *multivariate hypergeometric distribution* is the distribution of $c$
  random variables $X_1, ..., X_c$, defined by sampling $n$ elements without
  replacement from a set of size $N$ which contains $K_i$ elements of
  "type" $i$ (so that $N = sum_i=1^c K_i$). Each $X_i$ is defined as the number
  of elements sampled of type $i$.

  Just as the multinomial distribution extends the binomial distribution, the
  multivariate hypergeometric distribution is an extension of the
  hypergeometric distribution to scenarios where the elements being sampled
  come from more than two categories.
]

#proposition(<prop:hypergeometricna>)[@negativeassociation[~3.1]][
  Let $X_1, ..., X_c$ form a multivariate hypergeometric distribution. Then
  $X_1, ..., X_c$ are NA.
]

Finally, we prove a Chernoff bound on sums of NA indicator variables.

#proposition(<prop:nachernoff>)[Adapted from @Wajc2017NegativeA[~Theorem 5]][
  Let $I_1, ..., I_n$ be NA indicator variables, and let $X = sum_(k=1)^n I_k$.
  Then, for all $t >= 0$:

  $ Pr(X >= EE[X] + t) <= exp(- (t^2) / (2 (EE[X] + frac(t, 3, style: "horizontal")))). $
]

#proof[
  Let $Y ~ B(n, EE[X])$ Then, by @prop:nafunctions[-], we have that
  for all $u in RR$:

  $ EE[e^(u X)] = EE[e^(u sum_k I_k)] = EE[product_k e^(u I_k)] <= product_k EE[e^(u I_k)] = EE[e^(u Y)]. $

  So, applying the Chernoff bound to $X$, for all $u <= 0, t >= 0$:

  $
    Pr(X >= EE[X] + t)
    <= e^(- u(EE[X] + t)) EE[e^(u X)]
    <= e^(- u (EE[Y] + t)) EE[e^(u Y)].
  $

  Therefore, we can use the bound proved in @prop:chernoff[-]:

  $
    Pr(X >= EE[X] + t) <= exp(- (t^2) / (2 (EE[Y] + frac(t, 3, style: "horizontal")))) = exp(- (t^2) / (2 (EE[X] + frac(t, 3, style: "horizontal")))).
  $
]

= Algorithms
<sec:algorithms>

== The Greedy Algorithm

#let greedy = text(font: "New Computer Modern Sans")[Greedy]

The Greedy Algorithm (henceforth called #greedy) is defined as follows:

+ Iterate through the vertices in any fixed order.
+ For each vertex, assign it the smallest colour that has not been assigned to
  any of its neighbours.

It is not hard to see that this finds a $(Delta + 1)$-colouring for any graph.
However, while it does work well in some streaming contexts (e.g. vertex
streaming), the greedy algorithm is not a semi-streaming algorithm since it
requires $Omega(n^2)$ space (we can see this since the first produced colour
class must be a maximal set, and an edge-streaming algorithm that produces
a maximal independent set requires $Omega(n^2)$ space
@cormode2018independentsets @assadi_2019 @semistreamingmis).

== The Asymmetric Palette Sparsification (APS) Algorithm
<sec:aps>

The APS algorithm is defined as follows:

+ Uniformly sample a random permutation $pi: V -> [n]$.
+ Define the *list size* of a vertex
  $ ell(v) := min(Delta + 1, (40 n ln n) / pi(v)). $
  For each $v in V$ let the *palette* $L(v)$ be uniformly sampled from
  $[Delta + 1]$ such that $|L(v)| = ell(v)$. Let $cal(L) = {L(v) | v in V}$.
+ Let the conflict graph $G_cal(L) = (V, E_cal(L))$ be the subgraph of $G$
  with all edges $(u, v) in E$ such that $L(u) inter L(v) != wideemptyset$.
  During the stream, only store edges in $G_cal(L)$.
+ Finally, run #greedy on $G_cal(L)$ (where each node can only use the colours
  in its palette $𝐿(𝑣)$) in decreasing order of $pi(v)$, and return the
  resulting colouring.

// TODO: Explain this better
We present a proof that this algorithm is theoretically sound (i.e. with high
probability, it finds a $(Delta + 1)$-colouring of $G$ using $tilde(O)(n)$
space). This mainly follows the proof in #cite(<Assadi_2026>, form: "prose"),
the main differences being that we skip an intermediary step in the proof of
@thm:apst-delta[-], making the proof a bit simpler, and we prove the
$tilde(O)(n)$ memory bound happens with high probability, rather than just in
expectation.

#lemma(<lemma:listsizes>)[List sizes; see @Assadi_2026[~Lemma 3.2]][
  $sum_(v in V) ell(v) = O(n log^2(n))$ with certainty, and for any fixed
  vertices $u != v in V$,

  $ EE[ell(v)] = O(log^2(n)) quad "and" quad ell(u) dot ell(v) <= 2000 ln^4(n). $
]

This guarantees that palettes and their overlaps are small, which is useful
since we want to bound both the size of the palettes themselves, and the number
of edges for which they overlap.

#proof[
  First, using a bound on the harmonic series ($sum_(i = 1)^n frac(1, i, style: "horizontal") < ln n + 1$):

  $
    sum_(v in V) ell(v) & = sum_(v in V) min(Delta + 1, (40 ln n) / pi(v)) \
                        & <= sum_(v in V) (40 n ln n) / pi(v) = sum_(i = 1)^n (40 n ln n) / pi(v) \
                        & < (40 n ln n) (ln n + 1) = O(n log^2(n)).
  $

  For any $v in V$, since $pi$ is chosen uniformly, the distribution of
  $ell(v)$ is uniform, and so:

  $
    EE[ell(v)] = 1 / n sum_(u in V) ell(u) = ((40 n ln n) (ln n + 1)) / n
    = (40 ln n) (ln n + 1) = O(log^2(n)).
  $

  Finally, for $u != v in V$, again using the bound on the harmonic series:

  $
    EE[ell(u) dot ell(v)] & = sum_(i != j) Pr(pi(u) = i and pi(v) = j) dot ell(u) dot ell(v) \
                          & <= sum_(i != j) 1 / (n (n - 1)) dot (40 n ln n) / i dot (40 n ln n) / j \
                          & <= (1600 n^2 ln^2(n)) / (n (n - 1)) sum_(i = 1)^n sum_(j = 1)^n 1 / (i dot j) \
                          & <= 1600 ln^2(n) (ln n + 1)^2 <= 2000 ln^4(n).
  $
]

#definition[
  Given a vertex $v in V$, let $N_pi^<(v) := {u in N(v) | pi(u) < pi(v)}$.
  Since the greedy step at the end processes vertices in decreasing order of
  $pi(v)$, these are all the neighbours of $v$ processed _after_ $v$ by the
  greedy algorithm. Let $deg_pi^<(v) := |N_pi^<(v)|$.

  Similarly, let $N_pi^>(v) := {u in N(v) | pi(u) > pi(v)}$ be the neighbours
  of $v$ processed _before_ $v$ by the greedy algorithm, and let
  $deg_pi^>(v) := |N_pi^>(v)|$ (so $deg(v) = deg_pi^<(v) + deg_pi^>(v)$).
]

We observe that when colouring a specific vertex $v$, $v$ has at least $Delta +
1 - deg_pi^>(v)$ colours in $[Delta + 1]$ which have not been chosen by any of
its neighbours, although these colours may not be part of its palette.

With this in mind, we aim to find a lower bound on $deg_pi^<(v)$ for all
vertices $v$ with $ell(v) < deg(v) + 1$ (since if $ell(v) ≥ deg(v) + 1$, then
even if every vertex $u in N(v)$ has already been assigned a colour by the
greedy algorithm, $v$ must still be colourable since the number of colours it
has to choose from is greater than its degree). Since $ell(v)$ increases as
$pi(v)$ decreases, this ensures that we do not consider vertices processed at
the end of the greedy step (which are likely to have a lower $deg_pi^<(v)$) or
those with small degree.

#lemma(<lemma:degreebound>)[See @Assadi_2026[~Claim 3.3]][
  For all $v in V$,

  $ Pr(deg_pi^<(v) < (deg(v) pi(v)) / (2 n) mid(|) ell(v) < deg(v) + 1) <= n^(-5). $
]

#proof[
  Assume $ell(v) < deg(v) + 1$. Substituting the formula for $ell(v)$:

  $ (40 n ln n) / pi(v) < deg(v) + 1. $

  Rearranging for $pi(v)$ gives us:

  $ pi(v) > (40 n ln n) / (deg(v) + 1). $

  Fix a vertex $v in V$, and fix $pi(v)$ for that vertex. For $u in N(v)$,
  define $I_u$ as an indicator variable that is 1 if $u in N_pi^<(v)$, and 0
  otherwise. Note that $deg_pi^<(v) = sum_(u in N(v)) I_u$. In particular,
  since $pi(v)$ is chosen uniformly, $deg_pi^<(v)$ is a hypergeometric random
  variable, where $deg(v)$ vertices are sampled without replacement from $n -
  1$ total nodes, and a vertex is "good" if $pi(u) < pi(v)$ (so there are
  $pi(v) - 1$ "good" vertices in $V without {v}$).

  $ deg_pi^<(v) ~ "Hypergeometric"(n - 1, pi(v) - 1, deg(v)). $

  So then,

  $ EE[deg_pi^<(v)] = deg(v) (pi(v) - 1) / (n - 1). $

  And, using @prop:hypergeometric[-],

  $
    Pr(X <= (deg(v) pi(v)) / (2 n)) & <= exp(- 1 / (2 EE[X]) (EE[X] - (deg(v) pi(v)) / (2 n))^2) \
                                    & = exp(- 1 / (2 EE[X]) (deg(v) (pi(v) - 1) / (n - 1) - (deg(v) pi(v)) / (2 n))^2) \
                                    & <= exp(- 1 / (2 EE[X]) ((deg(v) (pi(v) - 1)) / (2 n))^2) \
                                    & = exp(- (n - 1) / (2 deg(v) (pi(v) - 1)) ((deg(v) (pi(v) - 1)) / (2 n))^2) \
                                    & <= exp(- (deg(v) (pi(v) - 1)) / (8 n)).
  $

  Substituting in the assumed bound on $pi(v)$:

  $
    Pr(X <= (deg(v) pi(v)) / (2 n)) & < exp(- deg(v) / (8 n) ((40 n ln n) / (deg(v) + 1) - 1)) \
                                    & <= exp(- (40 n ln n) / (8 n))
                                      = exp(-20 ln n) = n^(-5).
  $
]

#theorem(<thm:apst-delta>)[Asymmetric Palette Sparsification Theorem (for $(Delta + 1)$-colouring) @Assadi_2026][
  Let $G = (V, E)$ be any $n$-vertex graph with maximum degree $Delta$. Sample
  a random permutation $pi: V -> [n]$ uniformly and define:

  $ ell(v) := min(Delta + 1, (40 n ln n) / pi(v)) $

  for every $v in V$ as the size of the lists of colours to be sampled for
  vertex $v$. Then,

  - *List sizes*: $sum_(v in V) ell(v) = O(n log^2(n))$ with certainty, and for
    any fixed vertices $u != v in V$,

    $ EE[ell(v)] = O(log^2(n)) quad "and" quad EE[ell(u) dot ell(v)] = O(log^4(n)). $
  - *Colourability*: If for every vertex $v in V$, we sample a list $L(v)$ of
    $ell(v)$ colours from $[Delta + 1]$ uniformly and independently, then, with
    high probability (over the randomness of $ell$ and sampled lists) the
    greedy algorithm that iterates over vertices $v in V$ in the decreasing
    order of $pi(v)$ finds a proper list-colouring of $G$ from the lists
    ${L(v) | v in V}$.
]

#proof[
  *List sizes* follows immediately from @lemma:listsizes[-].

  For *Colourability*, let $v in V$. Let the set of *available colours*
  $A(v) subset.eq [Delta + 1]$ be the colours that have not yet been assigned
  to a neighbour of $v$ by the time we reach $v$ in the greedy step.

  Once again, we assume that $ell(v) < deg(v) + 1$, since otherwise by our
  earlier observation we can always assign $v$ a colour, and so the claim
  holds. So:

  $ pi(v) > (40 n ln n) / (deg(v) + 1). $

  Now, fix $pi$, and fix $L(u)$ for all vertices $u$ coloured before $v$ by
  the greedy step. This means that $A(v)$ and $ell(v)$ are fixed, but $L(v)$
  is still random.

  Since $L(v)$ is sampled uniformly, for a single colour $c in L(v)$, we have
  that:

  $ Pr(c in A(v)) = (|A(v)|) / (Delta + 1). $

  And, since $A(v)$ is fixed, the number of available colours sampled in $L(v)$
  is a hypergeometric random variable:

  $ |L(v) inter A(v)| ~ "Hypergeometric"(Delta + 1, |A(v)|, ell(v)). $

  By definition of $deg_pi^>(v)$ and $deg_pi^<(v)$:

  $
    (|A(v)|) / (Delta + 1) & = (Delta + 1 - deg_pi^>(v)) / (Delta + 1)
                             = 1 - (deg_pi^>(v)) / (Delta + 1)
                             >= 1 - (deg_pi^>(v)) / (deg(v) + 1) \
                           & = (deg(v) + 1 - deg_pi^>(v)) / (deg(v) + 1)
                             >= (deg_pi^<(v)) / (deg(v) + 1).
  $

  So then, using the PDF of the hypergeometric distribution,

  $
    Pr(|A(v) inter L(v)| = 0)
    &= (binom(|A(v)|, 0) binom(Delta + 1 - |A(v)|, ell(v))) / binom(Delta + 1, ell(v)) \
    &= (Delta + 1 - |A(v)|)! / (Delta + 1 - |A(v)| - ell(v))! dot (Delta + 1 - ell(v))! / (Delta + 1)! \
    &= (Delta + 1 - |A(v)|) / (Delta + 1) ... (Delta + 2 - |A(v)| - ell(v)) / (Delta + 2 - ell(v)).
  $

  Since for
  $b > a >= 1, frac(a, b, style: "horizontal") > frac(a - 1, b - 1, style: "horizontal")$,
  and $(1 - x)^r <= e^(-x r)$:

  $
    Pr(|A(v) inter L(v)| = 0) & <= (1 - (|A(v)|) / (Delta + 1))^ell(v)
                                <= (1 - (deg_pi^<(v)) / (deg(v) + 1))^ell(v)
                                <= exp(- (deg_pi^<(v) ell(v)) / (deg(v) + 1)).
  $

  Then, using @lemma:degreebound[-], and the definition of $ell(v)$:

  $
    Pr(|A(v) inter L(v)| = 0) & <= exp(- (deg(v) pi(v)) / (2 n) dot (40 n ln n) / pi(v) dot 1 / (deg(v) + 1))
                                <= exp(-10 ln n) <= n^(-5).
  $

  Finally, using a union bound over all vertices:

  $
    Pr(exists v in V med L(v) inter A(v) = wideemptyset)
    <= sum_(v in V) Pr(|L(v) inter A(v)| = 0)
    = n dot n^(-5) = n^(-4).
  $
]

We observe that a colouring of the conflict graph $G_cal(L)$ using the palettes
of each vertex is a colouring of the original graph $G$, since edges in $E
without E_cal(L)$ are between nodes with disjoint palettes. With this, we can
conclude that the algorithm produces a valid $(Delta + 1)$-colouring of $G$.

It remains to bound the memory of the algorithm.

#theorem[With high probability, the APS algorithm uses $tilde(O)(n)$ space.]

#proof[
  By @lemma:listsizes[-], we know that $cal(L)$ contains $O(n log^2(n))$ colours.

  Let $t := frac(2000 n ln^4(n), (Delta + 1), style: "horizontal")$.

  For any edge $(u, v) in E$, let $I_(u, v)$ be an indicator variable that is
  1 if $(u, v) in E_cal(L)$ and 0 otherwise. Then, using the tower rule, a
  union bound, and @lemma:listsizes[-]:

  $
    Pr((u, v) in E_cal(L)) & = EE[I_(u, v)] = EE[EE[I_(u, v) | ell(u), ell(v)]]
                             = EE[Pr(L(u) inter L(v) != wideemptyset | ell(u), ell(v))] \
                           & <= EE[(ell(u) dot ell(v)) / (Delta + 1)]
                             = (2000 ln^4(n)) / (Delta + 1).
  $

  Then $|E_cal(L)| = sum_((u, v) in E) I_(u, v)$. Note that for
  $(u, v) != (u', v') in E$, $I_(u, v)$ and $I_(u', v')$ are independent if
  $u != u'$ and $v != v'$ (the edges are not adjacent).

  By Vizing's theorem, there exists a $(Delta + 1)$-edge-colouring of $G$. In
  particular, we can partition $E$ into $Delta + 1$ matchings
  $E_1, E_2, ... E_(Delta + 1)$.

  For a given matching $E_i$, let $X_i = sum_((u, v) in E_i) I_(u, v)$ be the
  number of edges in $E_i inter E_cal(L)$.

  So, since $|E_i| <= n$,

  $
    EE[X_i] = sum_((u, v) in E_i) EE[I_(u, v)]
    = |E_i| (2000 ln^4(n)) / (Delta + 1)
    <= (2000 n ln^4(n)) / (Delta + 1) = t.
  $

  Consider the following equivalent method of sampling $L(v)$:
  - For each $v in V$, let $sigma_v$ be a random permutation of $[Delta + 1]$.
  - Let $L(v)$ be the first $ell(v)$ elements of $sigma_v$.

  Let $Sigma_V = {sigma_v | v in V}$.

  Let $Y_(u,v) := EE[I_(u,v) | Sigma_V]$. Then, for all $(u, v) in E_i$, the
  $Y_(u, v)$ variables are independent (since each one depends only on
  $sigma_u$ and $sigma_v$, and the edges in a matching are non-adjacent), and
  so we can apply @prop:chernoff[-] to $EE[X_i mid(|) Sigma_V] = sum_((u, v) in
  E_i) Y_(u,v)$ with our defined $t$:

  $
    Pr(EE[X_i mid(|) Sigma_V] >= EE[X_i] + t) & <= exp(- (t^2) / (2 (EE[X_i] + frac(t, 3, style: "horizontal"))))
                                                <= exp(- t / 4) \
                                              & = exp(- (500 n ln^4(n)) / (Delta + 1))
                                                <= exp(- 4 ln(n)) = n^(-4).
  $

  So, with high probability, $EE[X_i | Sigma_V] < 2t$.

  Now, fix $Sigma_V$. For each vertex $v$, $ell(v)$ is a monotone
  transformation of $pi(v)$. For a given edge $(u, v)$, since $sigma_u,
  sigma_v$ are fixed, $I_(u, v)$ is a monotone transformation of $ell(u)$ and
  $ell(v)$; furthermore, since no two edges in a matching are adjacent, for
  $(u, v) in E_i$, each $I_(u, v)$ depends on a disjoint subset of the vertex
  list sizes. So, since $pi(v)$ is a permutation distribution, by
  @prop:permutationna[-] and @prop:naclosure[-], the $I_(u,v)$
  variables are negatively associated. So, we can again apply a Chernoff bound
  using @prop:nachernoff[-].

  $
    Pr(X_i >= EE[X_i mid(|) Sigma_V] + t mid(|) Sigma_V) & <= exp(- (t^2) / (2 (EE[X_i mid(|) Sigma_V] + frac(t, 3, style: "horizontal")))).
  $

  Let
  $S$ be the event that $EE[X_i | Sigma_V] < 2t$, and recall that
  $Pr(S^c) <= n^(-4)$. Then, since the previous bound holds for all choices of
  $Sigma_V$,

  $
    Pr(X_i >= 3t) & = Pr(X_i >= 3t | S) Pr(S) + Pr(X_i >= 3t | S^c) Pr(S^c) \
                  & <= Pr(X_i >= 3t | S) + n^(-4) \
                  & <= exp(- (t^2) / (2 (2t + frac(t, 3, style: "horizontal")))) + n^(-4) \
                  & <= exp(- t / 8) + n^(-4)
                    <= 2 n^(-4).
  $

  Then, using a union bound over all $Delta + 1$ matchings,

  $
    Pr(exists i med X_i >= 3t)
    <= sum_(i = 1)^(Delta + 1) Pr(X_i >= 3t)
    = 2 (Delta + 1) n^(-4) <= 2 n^(-3).
  $

  So, with high probability, for all matchings $E_i$,
  $ |E_i inter E_cal(L)| = X_i <= 3t = (6000 n ln^4(n)) / (Delta + 1). $

  Finally,

  $
    |E_cal(L)| = sum_(i = 1)^(Delta + 1) |E_i inter E_cal(L)|
    <= 6000 n ln^4(n) = O(n log^4(n)).
  $

  So the total space used by the algorithm is

  $
    n + O(n log^2(n)) + O(n log^4(n)) = tilde(O)(n).
  $
]

== The Partitioning Algorithm
<sec:partition>

The partitioning algorithm is a simpler algorithm that performs well in
practice.

+ Let $m = frac(Delta, ln n, style: "horizontal")$. Partition $V$ using uniform
  sampling into equally sized sets $(V_1, V_2, ..., V_m)$.
+ During the stream, only store edges contained in $G[V_i]$ for some $i$.
+ Colour each $G[V_i]$ separately, and combine the results into a single
  colouring (where the colours used by each subgraph are disjoint).

Note that this can be viewed as a variant of the Palette Sparsification
Algorithm, but with

$ L(v) = {((i - 1) Delta) / m, ..., (i Delta) / m - 1} quad "for" v in V_i. $

This algorithm is similar to traditional random graph partitioning algorithms
(see e.g. @alon2020palettesparsification
@andoni2014parallelalgorithmsgeometricgraph @greedymapreducestreaming), the
main difference being that we create equally sized partitions, rather than
assigning vertices to partitions independently and randomly.

#theorem[With high probability, the partitioning algorithm uses $tilde(O)(n)$ space.]

#proof[
  For a single vertex $v in V$, suppose $v in V_i$ for some $i$. Then since
  $V_i$ is sampled uniformly, $deg_(G[V_i])(v)$ (the number of neighbours $u in
  N(v)$ with $u in V_i$) is a hypergeometric random variable.

  $ deg_(G[V_i])(v) ~ "Hypergeometric"(n - 1, n/m - 1, deg(v)). $

  Since $deg(v) <= Delta$,

  $
    EE[deg_(G[V_i])(v)] = deg(v) (frac(n, m, style: "horizontal") - 1) / (n - 1)
    <= deg(v) / m <= Delta / m = ln n.
  $

  Using @prop:hypergeometric[-], with $t = 6 ln n$,

  $
    Pr(deg_(G[V_i])(v) >= 7 ln n) & <= exp(- (36 ln^2(n)) / (2 (EE[deg_(G[V_i])(v)] + 2 ln n))) \
                                  & <= exp(- (36 ln^2(n)) / (6 ln n)) \
                                  & = exp(- 6 ln n) = n^(-6).
  $

  Finally, by taking a union bound over all vertices $v in V$,

  $
    Pr(exists V_i med exists v in V_i thick deg_(G[V_i])(v) >= 7 ln n)
    <= sum_(v in V) n^(-6)
    = n dot n^(-6) = n^(-5).
  $

  Let $E'$ be the edges stored by the algorithm. With high probability,

  $
    |E'| = 1/2 sum_(V_i, v in V_i) deg_(G[V_i])(v)
    <= 1/2 sum_(v in V) 7 ln n
    = 7/2 n ln n = tilde(O)(n).
  $
]

To finish this section, we will show that the partitioning algorithm does not
guarantee a $(Delta + 1)$-colouring on all graphs:

#theorem(<thm:partition>)[
  Let $G = (V, E)$ be an $n$-vertex graph made up of $sqrt(n)$ disconnected
  cliques (so that $Delta = sqrt(n) - 1$). Then the partitioning algorithm
  finds a colouring of size at least $2 Delta$ with high probability.
]

We begin with the following.

#lemma(<lemma:singlepartition>)[
  Let $V_i$ be a random partition sampled from $G$ of size
  $m = frac(Delta, ln n, style: "horizontal")$. For a clique $K$ of $G$, let
  $X_(i,K)$ be the number of vertices in $K$ assigned to $V_i$. Then for large
  enough $n$,

  $ Pr(X_(i,K) >= 2 ln n) >= n^(-0.4). $
]

#proof[
  Since $V_i$ is sampled uniformly, and each clique is of size $sqrt(n)$,

  $ X_(i,K) ~ "Hypergeometric"(n, n / m, sqrt(n)). $

  So:

  $
    Pr(X_(i,K) >= x) >= Pr(X_(i,K) = x)
    & = (binom(n / m, x) binom(n - n / m, sqrt(n) - x)) / binom(n, sqrt(n)) \
    &= ((n/m) ... (n/m - x + 1)) / x! ((n - n/m) ... (n - n/m - sqrt(n) + x + 1)) / (sqrt(n) - x)! (sqrt(n))! / (n ... (n - sqrt(n) + 1)) \
    &>= binom(sqrt(n), x) ((n / m - x)^x (n - n/m - sqrt(n))^(sqrt(n) - x)) / n^sqrt(n) \
    & >= binom(sqrt(n), x) ((n/m - x) / n)^x ((n - n/m - sqrt(n)) / n)^(sqrt(n) - x).
  $

  Substituting in
  $m = frac(Delta, ln n, style: "horizontal") = frac((sqrt(n) - 1), ln n, style: "horizontal")$:

  $
    Pr(X_(i,K) >= x) >=
    binom(sqrt(n), x) ((ln n) / sqrt(n) - x / n)^x (1 - (ln n + 1) / sqrt(n))^(sqrt(n) - x).
  $

  Using $binom(n, k) >= ((n e) / k)^k$ and $(1 + x/m)^m approx e^x$, we get:

  $
    Pr(X_(i,K) >= x) & >= ((sqrt(n) e) / x)^x ((ln n) / sqrt(n) - x / n)^x e^(-1 - ln n)
                       = ((e ln n) / x - e / sqrt(n))^x e^(-1) n^(-1).
  $

  With $x = 2 ln n$, we get:

  $
    Pr(X_(i,K) >= 2 ln n) & >= (e / 2 - (sqrt(n) e) / n)^(2 ln n) e^(-1) n^(-1)
                            = (n^(2 ln (e / 2))) (1 - o(1)) e^(-1) n^(-1) \
                          & approx e^(-1) n^(0.614) dot n^(-1)
                            = e^(-1) n^(-0.386) >= n^(-0.4).
  $
]

#lemma(<lemma:singleclique>)[
  With high probability, there is at least one clique $K$ of $G$ such that
  $X_(i,K) >= 2 ln n$.
]

#proof[
  Let $cal(K) = {K}$ be the set of cliques in $G$. Let
  $p = Pr(X_(i,K) >= 2 ln n)$ (by @lemma:singlepartition[-], this is at least
  $n^(-0.4)$). For each $K in cal(K)$, let $I_(i,K)$ be an indicator variable
  that is 1 if $X_(i,K) >= 2 ln n$, and 0 otherwise. Let $Y_i = sum_(K in
  cal(K)) I_(i,K)$.

  By linearity of expectation:

  $ EE[Y_i] = sum_(K in cal(K)) EE[I_(i,K)] = p sqrt(n). $

  $(X_K)_(K in cal(K))$ form a multivariate hypergeometric distribution, and so
  the random variables are negatively associated by
  @prop:hypergeometricna[-]. Then, using @prop:marginalbounds[-],

  $
    Pr(Y_i = 0) = Pr(and.big_(K in cal(K)) X_(i,K) < 2 ln n)
    <= product_(K in cal(K)) Pr(X_(i,K) < 2 ln n)
    = (1 - p)^(sqrt(n)).
  $

  Using $(1 - x)^r <= e^(-x r)$:

  $
    Pr(Y_i = 0) <= exp(- p sqrt(n)) <= exp(- n^(-0.4) dot n^(0.5))
    = exp(- n^(0.1)).
  $
]

#remark[
  If a partition has at least $2 ln n$ vertices from a particular clique, then
  it cannot be coloured with fewer than $2 ln n$ colours.
]

#proof[@thm:partition][
  To achieve the desired result, we take a union bound over all partitions
  $X_i$:

  $
    Pr(exists i med Y_i = 0) <= sum_(i = 1)^(m) Pr(Y_i = 0) <= m exp(-n^(0.1))
    = Delta / (ln n) exp(-n^(0.1)).
  $

  Let $C$ be the total number of colours used by the algorithm. With high
  probability, every $Y_i > 0$, and so each partition $X_i$ must use at least
  $2 ln n$ colours. Since there are $m$ partitions:

  $
    C >= m dot 2 ln n = 2 Delta.
  $
]

#cite(<alon2020palettesparsification>, form: "prose") explore some of the
properties of this algorithm (or, at least, a variant of it where vertices
assigned to partitions independently) with different choices of $m$ and
different properties of $G$.

= Implementations
<sec:implementations>

In practice, we make many changes to the three algorithms, to improve
performance (in terms of speed, memory and colouring quality) on real-world
graphs.

Experiments were run on a Lenovo ThinkPad T14 Gen 2i running Fedora Linux, with
an Intel Core i5-1135G7 processor, 16 GB of DDR4 RAM, using a Btrfs
filesystem on an NVMe SSD. All code was written in C++, compiled using gcc
version 16.0.1, with the following compiler flags for optimisation:
`-O3 -march=native`.

== Reading graphs

Graphs are stored as TSV files of edges. Initial implementations of the three
algorithms saw reading and parsing the files take up the vast majority of time.
Work was done, therefore, to optimise this as much as possible, enabling better
comparisons of the algorithms.

Two approaches for reading were explored:

+ Opening the file using Linux's `O_DIRECT`, bypassing the kernel cache.
+ Using Unix's `mmap()` to memory map the file onto the program's address
  space, avoiding having to copy the data into a user-space buffer.

The advantage of both is that they avoid unnecessary copies into an
intermediary buffer. For both approaches, numbers are then parsed using
`std::from_chars()`, which is fast, non-allocating and locale-independent.

The two methods were tested by parsing a large graph file containing around 1M
edges. The results are shown in @fig:reading-benchmarks. We compare the two
approaches to the original, "naive" approach (using `std::ifstream` and `>>`),
and conclude that while both are significantly better than the naive approach,
the `mmap` method is slightly faster and more consistent overall.

#figure(
  table(
    columns: 4,
    table.header([], [*Minimum time*], [*Maximum time*], [*Average time*]),

    [Naive method], [7.24367s], [7.66455s], [7.4271s],
    [`O_DIRECT`], [2.25147s], [2.29236s], [2.26911s],
    [`mmap`], [2.05847s], [2.112s], [2.08183s],
  ),
  caption: [Time taken to read the edges of a graph with over 100M edges],
) <fig:reading-benchmarks>

== Storing graphs
<sec:storinggraphs>

Graphs are stored in adjacency list format, since only neighbourhood queries
are needed. All three algorithms result in a final greedy step, so we optimise
slightly by, for each vertex $v$, only storing the neighbours of $v$ that are
processed before it in the greedy step (since the neighbours processed after
$v$ will not have been assigned a colour when $v$ is processed). This allows us
to use half the storage we normally would.

== The Greedy Algorithm

The most computationally expensive part of the greedy algorithm (besides
reading and storing the graph) is finding the first available colour for a
vertex $v$. The usual approach is to store an array of booleans, where the ith
entry is true if the ith colour is taken by one of $v$'s neighbours, and false
otherwise. The first available colour is then the first entry that is false.

We experimented with using a bitset instead, and using gcc's `__builtin_ctzll`
to find the first available colour. However, this was not found to be faster
(see @fig:greedy-benchmarks).

#figure(
  table(
    columns: 4,
    table.header([], [*Minimum time*], [*Maximum time*], [*Average time*]),

    [Array], [0.962989s], [1.00336s], [0.972211s],
    [Bitset], [1.00157s], [1.03284s], [1.01549s],
  ),
  caption: [Time taken to colour a graph with over 100M edges],
) <fig:greedy-benchmarks>


== The Asymmetric Palette Sparsification Algorithm
<sec:apsoptim>

The following changes were made to the APS algorithm:

- The initial step of the algorithm, shuffling the vertices, is mainly done
  to make sure adversarial graphs cannot break the algorithm. In practice, we
  do not expect real-world graphs to be adversarial, and this step did not
  result in better quality colourings, so it was removed (essentially letting
  $pi(v_i) = i$ for all $v in V$). This results in slightly reduced memory
  usage (since we do not have to store the permutation) and an increase in
  performance (since the greedy step can iterate through vertices in order,
  which more cache-friendly).
- The stated formula for $ell(v)$ resulted in a very small proportion of
  edges being skipped. We tested a handful of potential functions for $ell$,
  and settled on $ell(v) = c dot pi(v)^(-x)$, where $c$ and $x$ are parameters
  to the algorithm.
- On real graphs, the greedy algorithm often found colouring several orders of
  magnitude smaller than $Delta + 1$. However, due to the nature of the APS
  algorithm (recall that palettes are sampled randomly from $[Delta + 1]$), it
  does not usually produce colourings smaller than $Delta + 1$. For this reason,
  we replace $Delta + 1$ with a parameter, which we call `max_colours`.
- Real graphs are often quite sparse. In such cases, the memory cost of storing
  the palette of each vertex often dominates the memory use of the algorithm.
  Instead, for each $v in V$, we store $ell(v)$ and a randomly generated
  seed. To retrieve $L(v)$, we initialise a random number generator (RNG)
  using $v$'s seed, and use it to sample $ell(v)$ colours. Since an RNG with
  a fixed seed is deterministic, so is the produced $L(v)$. We call this technique
  _palette compression_. Since only 2 numbers are needed to store a palette,
  this approach uses much less memory, but comes at a significant runtime cost;
  hence, we run experiments with and without this change.

Depending on the values of $c$, $x$, and `max_colours`, the APS algorithm is
sometimes unable to assign each vertex a colour from its palette. Instead, if
the greedy step is unable to find a colour for $v$ from its palette, we assign
it a new, globally unique colour.

== The Partitioning Algorithm

The following changes were made to the partitioning algorithm:

- Instead of fixing $m = frac(Delta, ln n, style: "horizontal")$, we treat $m$
  as a parameter to the algorithm.
- Instead of sampling $(V_1, ..., V_m)$ randomly, by the same justification
  as for abandoning the shuffling step in the APS algorithm, we pick the
  partitions deterministically ($v_i in V_j <=> i equiv j med (mod m)$).

== A Second Pass

We experiment with giving each algorithm a second pass over the edge stream,
with the aim of improving colouring quality and memory use at the cost of time.

=== The Greedy Algorithm

The greedy algorithm does not stand to gain much from a second pass, since it
loads the entire graph into memory. However, we explored using an initial pass
to record the degree of each node. This allows us to allocate the neighbour
list of each vertex in advance. In fact, it allows us to store the graph in
Compressed Sparse Row (CSR) format, where the neighbours of every vertex are
stored in a single, flat array, alongside a secondary array of offsets. This
improves data locality and reduces allocation overhead, along with using less
memory (since no unnecessary or "extra" memory is allocated).

=== The APS Algorithm

We noticed that the APS algorithm, with well-chosen values of $c$, $x$ and
`max_colours`, is often able to assign almost every vertex a colour from its
palette. However, since uncoloured vertices are assigned a globally unique
colour, even a small number of uncoloured vertices can result in a much larger
colouring.

With this in mind, we instead do not give these nodes a colour during the first
pass. Call the set of uncoloured vertices $U$. Then the second pass is defined
as follows:

+ During the stream, only store edges $(u, v) in E$ with $u in U$ or $v in U$.
+ Iterate through the vertices $v in U$, and use the greedy algorithm to assign
  each a colour.

Since we store "complete" information about the vertices of $U$ during the
second pass, the resulting colouring will be smaller, and, provided that $U$
is small, will not use much memory.

=== The Partitioning Algorithm

The logic behind the second pass of the partitioning algorithm is that many
of the colour classes are likely to be small, especially if $m$ is large,
meaning that many of the colour classes of different partitions may have no
edges between them, meaning they can be "merged" into a single colour class.

Finding all the colour classes that can be merged is itself a colouring
problem, in the following sense. Let $phi$ be a $k$-colouring of $G$. Define
the *colour graph* $H = (V_H, E_H)$, where $V_H = [k]$ and $(c, d) in E_H <=>
exists (u, v) in E med phi(u) = c and phi(v) = d$. In other words, the colour
graph contains the colours of $phi$ as nodes, with edges representing there
being at least one edge between the two corresponding colour classes. If two
vertices in $H$ have no edge between them, then the colour classes can be
merged.

With this, we define the second pass:

+ Assume the first pass has produced a $k$-colouring $phi$. During the stream,
  construct the colour graph $H$ (upon receiving $(u, v) in E$, add
  $(phi(u), phi(v))$ to $E_H$).
+ Run #greedy on $H$ to find a colouring $psi$.
+ Return the combined colouring $(psi compose phi)$.

Note that in general, $|E_H| != tilde(O)(n)$ - consider a clique, in which
case $G tilde.equiv H$.

=== Prior information

Each algorithm is given the number of nodes in the graph as input. We consider
this reasonable information for the algorithms to know beforehand - but it may
be useful to note that each of the algorithms could be simply modified to work
for an unknown number of vertices (the APS algorithm, for instance, would have
to generate its list of palettes on-demand).

= Experiments
<sec:experiments>

#let epinions = text(font: "New Computer Modern Sans")[epinions]
#let amazon = text(font: "New Computer Modern Sans")[amazon]
#let fpsol = text(font: "New Computer Modern Sans")[fpsol]
#let dblp = text(font: "New Computer Modern Sans")[dblp]
#let gnutella = text(font: "New Computer Modern Sans")[gnutella]
#let roads = text(font: "New Computer Modern Sans")[roads]

We test our algorithms on six real-world graphs:

#epinions ("soc-Epinions1") is an online social network of the consumer review
site Epinions.com. It has a low average degree, but a small number of "hub"
vertices with much higher degrees, making the maximum degree very large.

#amazon ("amazon0302") is a product co-purchasing network for Amazon. It links
together products that are frequently co-purchased together on the Amazon
website. It can be coloured with very few colours.

#dblp ("com-dblp") is a co-authorship network taken from the DBLP computer
science bibliography. Two authors are connected if they publish at least one
paper together.

#gnutella ("p2p-Gnutella04") is a snapshot of the Gnutella peer-to-peer file
sharing network, where nodes represent hosts and edges represent connections
between them.

#roads ("roadNet-PA") is a road network of Pennsylvania, where edges represent
roads, and nodes represent intersections or endpoints. It is a large but very
sparse (almost planar) graph, and so can be coloured using very few colours.

#fpsol ("fpsol2.i.1") is a graph representing a register allocation problem
generated by real code. It was used in the second DIMACS Implementation
Challenge to benchmark graph colouring algorithms. Notably, it is much smaller
than the other graphs, containing less than 500 nodes; however, it is very
dense.

Most of these networks (besides #fpsol) were taken from the Stanford Large
Network Dataset Collection @snapnets.

#figure(
  table(
    columns: 5,
    table.header([*Graph*], [*Nodes ($|V|$)*], [*Edges ($|E|$)*], [*Max Degree ($Delta$)*], [*Average degree*]),
    [#amazon], [262,111], [1,234,877], [425], [9.42],
    [#dblp], [425,957], [1,049,866], [343], [4.93],
    [#epinions], [75,888], [508,837], [3,079], [13.4],
    [#gnutella], [10,879], [39,994], [103], [7.35],
    [#roads], [1,090,920], [3,083,796], [18], [5.65],
    [#fpsol], [497], [11,654], [252], [46.9],
  ),
  caption: [Properties of the graphs],
) <table:graph-properties>

== Investigating the size of the conflict graph

For both the APS algorithm and the partitioning algorithm, we investigate the
relationship between the number of edges stored in the conflict graph and the
size of the returned colouring. The former measure is a useful proxy for
memory use, with the advantage of being implementation-agnostic (and, in the
case of the partitioning algorithm, deterministic). It is especially useful
to provide a comparison between the two algorithms.

For the partitioning algorithm, which has only one parameter, to analyse this
tradeoff for a given graph, we simply run the algorithm over a range of values
of $m$. Increasing $m$ generally stores fewer edges at the cost of larger
colourings, so this allows us to nicely visualise the tradeoff between these
two factors.

Analysing the APS algorithm is a bit more complex. The algorithm has three
parameters ($c$, $x$, and `max_colours`), two of which are continuous. For a
single graph, we are interested in the "best" choices of parameters for that
graph, since it provides an upper bound on the algorithm's performance.

Finding optimal choices for $c$, $x$ and `max_colours` can be viewed as a
multi-objective optimisation problem, where the objectives are to minimise
both the number of edges in the conflict graph and the size of the colouring.
A combination of parameters is called _Pareto optimal_ if there are no other
parameter choices that result in both a smaller conflict graph _and_ a smaller
colouring. We would like to find the _Pareto front_, the set of all Pareto
optimal parameter choices.

One way of doing this is to perform a grid search over all possible combination
of parameter choices. However, this ended up being too slow, especially for
larger graphs. Instead, we used Optuna @akiba2019optuna, a Python optimisation
library, to more quickly find the Pareto front.

Since the APS algorithm is random, certain parameter choices may perform better
simply by random chance. Therefore, for each choice of parameters (which we
call an experiment), the algorithm is run 50 times, and an average is returned.

The results are shown in @fig:pareto_fronts.

#figure(
  image("plots/pareto_fronts.pdf"),
  caption: [Colours/edges tradeoff of the three algorithms],
) <fig:pareto_fronts>

We can see that both the partitioning algorithm and the APS algorithm are able
to produce colourings of a similar size to the greedy algorithm, using a
significantly smaller conflict graph. However, the partitioning algorithm
outperforms the APS algorithm on all of the graphs.

To understand this performance gap, we can look at how optimal parameter choices
are found and palettes are assigned.

#let max_colours = `max_colours`

Suppose, for some choice of parameters, the APS algorithm has produced a
$k$-colouring. As explained in @sec:apsoptim, $k$ is unlikely to be less than
`max_colours` due to the way palettes are sampled. However, if $k$ is larger
than `max_colours` then $k - #max_colours$ nodes have been assigned a
globally unique colour. For this reason, we should expect $k approx
#max_colours$ for optimal parameter choices.

// #figure(
//   image("plots/max_colours_relationship.pdf"),
//   caption: [Relationship between `max_colours` and colouring size for Pareto-optimal trials],
// ) <fig:max_colours_relationship>

This allows us to see our optimisation problem in a different light: for a
target colouring of size $k$, we fix $#max_colours := k$ and then find optimal
values of $c$ and $x$ so that the size of the conflict graph is minimised, but
each vertex is able to be assigned a colour from its palette. For a single
choice of $c$ and $x$, we can calculate the _average palette size_ by
calculating $EE[ell(v)]$.

On the other hand, as stated in @sec:partition, the partitioning algorithm can
be viewed as a variant of the Palette Sparsification algorithm, with each node
given a palette according to the partition it is assigned to. For a target
colouring of size $k$, the available colours are divided between the
partitions. This effectively assigns each vertex in a partition a palette of
size approximately $frac(k, m, style: "horizontal")$.

With this, we can compare the average palette sizes of the two algorithms.
@fig:average_palette_sizes demonstrates that the partitioning algorithm is able
to assign each vertex a larger palette while skipping more edges than the APS
algorithm.

#figure(
  image("plots/average_palette_sizes.pdf"),
  caption: [Average palette sizes vs edges stored for the APS and partitioning algorithms],
) <fig:average_palette_sizes>

=== Two pass algorithms

We do the same analysis on the two pass variants of the partitioning and APS
algorithm. Both algorithms store a graph in the second pass - in the case of
the partitioning algorithm, the colour graph; in the case of the APS algorithm,
the graph of uncoloured nodes. We use the maximum number of edges stored in
the conflict graph or the graph in the second pass as our proxy for memory -
this is a measure of the maximum number of edges stored at any one time.

The results are shown in @fig:pareto_fronts_both_passes.

#figure(
  image("plots/pareto_fronts_both_passes.pdf"),
  caption: [Colours/edges tradeoff of the three algorithms, including second passes],
) <fig:pareto_fronts_both_passes>

Giving the APS algorithm a second pass allows it to find better quality
colourings while storing network edges. However, it still does not outperform
even the single pass partitioning algorithm.

The partitioning algorithm's second pass, for smaller values of $m$, improves
colouring quality significantly. However, quite quickly, the size of the colour
graph in the second pass becomes larger than the size of the conflict graph in
the first pass, // (see @fig:partition_two_pass_edges),
and so for larger values of
$m$, using a second pass is no longer helpful due to the increased memory use.

// #figure(
//   image("plots/partition_two_pass_edges.pdf"),
//   caption: [Edges stored by the first and second passes of the partitioning algorithm],
// ) <fig:partition_two_pass_edges>

== Memory and speed

We analyse the memory and time used by each of the algorithms. For memory, we
measure both the peak memory - the maximum amount of memory allocated at any
one time - and the total memory allocated over the total running-time of the
algorithm. For time, we record the time each algorithm takes to complete over
twenty runs, and take an average.

For the APS algorithm, we benchmark runs of the algorithm using the set of
Pareto-optimal parameters found earlier. We order them in increasing order of
colouring size, and index them by $i$.

The plots of the data for the full set of graphs can be found in
#link(<appx:graphs>)[Appendix B].

The partitioning algorithm is able to find colourings that are near the quality
of the greedy algorithm, while using less memory and time (see
@fig:epinions_partition). As $m$ increases, the memory and time used drop
significantly, but the colouring size increases. Since the memory-used by the
algorithm is inherently bounded below by the cost of storing the nodes and the
colouring, the memory use plateaus, and this effect happens earlier for sparser
graphs.

#figure(
  image("plots/epinions_partition.pdf"),
  caption: [Colouring size, memory and time used by the partitioning algorithm on #epinions],
) <fig:epinions_partition>

// #figure(
//   image("plots/roads_partition.pdf"),
//   caption: [Colouring size, memory and time used by the partitioning algorithm on #roads],
// ) <fig:roads_partition>

The performance of the APS algorithm is more varied. On most of the graphs,
storing the full palettes for each vertex dominates the memory use. However,
storing the palettes as a seed and length slows down the algorithm (see
@fig:dblp_palette_compressed_comparison).

#figure(
  image("plots/dblp_palette_compressed_comparison.pdf"),
  caption: [Colouring size, memory and time used by the APS algorithm on #dblp, with and without palette compression],
) <fig:dblp_palette_compressed_comparison>

With palette compression, the APS algorithm is able to find colourings using
less memory than the greedy algorithm for #epinions and #fpsol. Its performance
on the other three is more varied: on #amazon, it uses roughly the same amount
of memory, while on the other three, it uses strictly more. Unsurprisingly,
it does not perform better than the partitioning algorithm.

// #figure(
//   image("plots/epinions_palette_compressed.pdf"),
//   caption: [Colouring size, memory and time used by the APS algorithm on #epinions, with palette compression],
// ) <fig:epinions_palette_compressed_comparison>
//
// #figure(
//   image("plots/roads_palette_compressed.pdf"),
//   caption: [Colouring size, memory and time used by the APS algorithm on #roads, with palette compression],
// ) <fig:roads_palette_compressed_comparison>

=== Two pass algorithms

We analyse the performance of the three algorithms when given a second pass.

For the greedy algorithm, its second pass allows it to store the graph in a
more memory efficient format; as such, we expect peak memory usage to decrease
at the cost of time. The memory use does decrease on all the graphs, as shown
in @fig:greedy_passes; however, for all of the graphs besides #fpsol, the
two-pass greedy algorithm uses less time as well. This is perhaps unsurprising
when we recall that the main bottleneck for the (single pass) greedy algorithm
is storing the graph (and in particular, allocating and reallocating the
adjacency lists of each vertex), and so our two pass variant is able to
sidestep some of this cost by allocating memory for the entire graph upfront.

#figure(
  image("plots/greedy_passes.pdf"),
  caption: [Comparison of the performance of the greedy algorithm given one or two passes],
) <fig:greedy_passes>

Allowing the partitioning algorithm a second pass allows it to find better
quality colourings using less memory, at the cost of time. We showed earlier
that as $m$ increases, the number of edges stored in the conflict graph is
eventually outweighed by the number of edges stored in the colour graph.
However, in practice, for all of the graphs besides #fpsol, the peak memory use
of the algorithm does not change when given a second pass. This is because in
the first pass, we have to store all the nodes in the graph, which creates a
lower bound on the memory use of the algorithm. Since these nodes are not
stored during the second pass, if the cost of storing the colour graph is less
than the cost of storing the nodes, then the peak memory use is not affected
by the second pass.

#figure(
  image("plots/epinions_partition_two_pass_comparison.pdf"),
  caption: [Comparison of the performance of the partitioning algorithm on #epinions given one or two passes],
) <fig:epinions_partition_two_pass_comparison>

// #figure(
//   image("plots/fpsol_partition_two_pass_comparison.pdf"),
//   caption: [Comparison of the performance of the partitioning algorithm on #fpsol given one or two passes],
// ) <fig:fpsol_partition_two_pass_comparison>

The APS algorithm also benefits slightly from its second pass, allowing
it to find better quality colourings whilst using less memory. Even with
this, it still does not do better than the partitioning algorithm.

#figure(
  image("plots/epinions_palette_pass_comparison.pdf"),
  caption: [Comparison of the performance of the APS algorithm on #epinions given one or two passes],
) <fig:epinions_palette_pass_comparison>

// === A larger graph
//
// Finally, we test our algorithms on a much larger graph: the Friendster social
// network. This is an incredibly large network, with over x nodes and y edges.
// It is an interesting example because, on the machine we tested on, the greedy
// algorithm was unable to find a colouring without running out of memory.
//
// On the other hand, with the right parameters, the partitioning and APS
// algorithm are able to colour the network. The partitioning algorithm performs
// particularly well, being able to find a colouring without running out of memory
// even with only two partitions.
//
// TODO

= Conclusion
<chap:conclusion>

In this paper, we showed that the Asymmetric Palette Sparsification of
#cite(<Assadi_2026>, form: "prose") performs worse on real-world graphs
than a simpler approach using graph partitioning. We showed that giving
the APS algorithm a second pass allows it to match the performance of
the partitioning algorithm.

It is known that iterating over vertices in a certain order (in decreasing
order of degree, for instance) can result in #greedy returning smaller
colourings @colouringalgorithms. We did not explore this in our paper, partly
because if the ordering depends on some unknown property of the graph, we would
need to forego the optimisation described in @sec:storinggraphs, requiring us
to store twice as many edges (or use an initial pass to compute the ordering
before parsing the graph). However, since all three algorithms use #greedy,
further work could explore the effect of different vertex orderings on the
three algorithms.

The APS algorithm stands to benefit particularly from an initial pass to
calculate vertex degree, since we could assign larger palettes to vertices
with larger degree (in fact, as we pointed out in @sec:aps, giving a vertex $v$
a palette of size $deg(v) + 1$ ensures it will be assigned a colour in its
palette).

Further work could also explore other ways to improve the two-pass variants
of each of the algorithms - especially the partitioning algorithm, for which
our attempt at a second pass came at a severe memory cost. One could explore
more optimal methods of assigning vertices to partitions given some prior
knowledge about the graph.

// ─────────────────────────────────────────────────────────────────────────────
// BACK MATTER — Bibliography
// ─────────────────────────────────────────────────────────────────────────────

#counter(heading).update(0)

#pagebreak()
#show bibliography: set heading(outlined: false)
#bibliography("dissertation.bib", style: "association-for-computing-machinery")

// ─────────────────────────────────────────────────────────────────────────────
// APPENDICES
// ─────────────────────────────────────────────────────────────────────────────

#pagebreak()
#heading(numbering: none, outlined: false)[Appendices]

#set heading(numbering: "A.1")
#counter(heading).update(0)

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(1cm)
  if counter(heading).get().first() > 0 {
    text(size: 17pt, weight: "bold")[Appendix #counter(heading).display()]
    v(0.3cm)
  }
  text(size: 24pt, weight: "bold")[#it.body]
  v(0.5cm)
}

// ── Appendix A: AI Prompts/Tools (COMPULSORY) ─────────────────────────────────
#pagebreak()
= Appendix A: AI Prompts / Tools
<appx:ai>

TODO

// ── Appendix B: Example Appendix ─────────────────────────────────────────────
#pagebreak()
= Appendix B: Graphs
<appx:graphs>

== Algorithm performance graphs

#let graphs = (
  epinions: epinions,
  amazon: amazon,
  fpsol: fpsol,
  dblp: dblp,
  gnutella: gnutella,
  roads: roads,
)

#for (name, text) in graphs {
  [=== Performance on #text]

  let plots = (
    "partition": [Partitioning algorithm],
    "partition_two_pass": [Two-pass partitioning algorithm],
    "palette": [APS algorithm],
    "palette_compressed": [APS algorithm (with palette compression)],
    "palette_two_pass": [Two-pass APS algorithm],
    "palette_two_pass_compressed": [Two-pass APS algorithm (with palette compression)],
  )

  for (plot_name, caption) in plots {
    figure(
      image("plots/" + name + "_" + plot_name + ".pdf"),
      caption: caption,
      outlined: false,
    )
  }
}
