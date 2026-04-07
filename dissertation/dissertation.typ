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

#text(weight: "bold")[A compulsory section, of at most 300 words]
#v(0.5cm)

This section should give an overview of the project context, aims and
objectives, and main contributions (e.g., deliverables) and achievements. The
goal is to ensure the reader is clear about what the topic is, what you have
done within this topic, _and_ what your view of the outcome is.

// ── Dedication & Acknowledgements ────────────────────────────────────────────
= Dedication and Acknowledgements
<chap:acknowledgements>

#v(0.5cm)

It is common practice (although totally optional) to acknowledge any
third-party advice, contribution or influence you have found useful during your
work.

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

#text(weight: "bold")[A compulsory section]
#v(0.5cm)

In almost every project, this will be one of the following statements:
- "This project did not require ethical review, as determined by my supervisor, [fill in name]"; or
- "This project fits within the scope of ethics application 6683, as reviewed by my supervisor, [fill in name]"; or
- "An ethics application for this project was reviewed and approved by the faculty research ethics committee as application [fill in number]".

See #link("https://cs-uob-individual-project.github.io/ethics/")[the ethics webpage] for more information.

// ── Summary of Changes ───────────────────────────────────────────────────────
= Summary of Changes
<chap:changes>

#text(weight: "bold")[Compulsory only if the dissertation is a resubmission, otherwise delete]
#v(0.5cm)

If and only if the dissertation represents a resubmission (e.g., as the result
of a resit), this section is compulsory: the content should summarise all
non-trivial changes made to the initial submission.

// ── Supporting Technologies ──────────────────────────────────────────────────
= Supporting Technologies
<chap:tech>

This section should present a detailed summary, in bullet point form, of any
third-party resources (e.g., hardware and software components) used during the
project.

// ── Notation and Acronyms ────────────────────────────────────────────────────
= Notation and Acronyms
<chap:notation>

Any well written document will introduce notation and acronyms before their
use, even if they are standard in some way.

#table(
  columns: (auto, auto, 1fr),
  stroke: none,
  [AES], [:], [Advanced Encryption Standard],
  [DES], [:], [Data Encryption Standard],
  [...], [...], [...],
)

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

Let $G = (V, E)$ be an $n$-vertex graph with maximum degree $Delta$. A
_$k$-colouring_ is a function $phi: V -> [k]$ such that for every $(u, v) in E$,
$phi(u) != phi(v)$. In other words, we assign a colour to every vertex so that
no two adjacent vertices have the same colour. Graph colouring is a ubiquitous
problem in graph theory, and it enjoys many applications, including scheduling,
register allocation and Sudoku.

One simple algorithm is the greedy algorithm, which iterates through vertices,
assigning each vertex the smallest colour that has not been assigned to its
neighbours. This runs in linear time, and guarantees a $(Delta + 1)$-colouring.

We are interested in the semi-streaming space, where edges come in one at a
time, and we are only allowed to use $tilde(O)(n)$ ($O(n "polylog" n)$) space.
The greedy algorithm fails here, since it requires the entire graph to be
stored in memory.

An algorithm that is able to produce colourings of similar quality to the
greedy algorithm while using less memory are desirable in many scenarios.
For example, TODO....

In 2018, Assadi, Chen and Khanna @assadi_2019 proved the following:

#theorem(<thm:pst>)[Palette Sparsification Theorem @assadi_2019][
  Let $G = (V, E)$ be an $n$-vertex graph with maximum degree $Delta$. Suppose
  for any vertex $v in V$ , we sample $O(log n)$ colours $L(v)$ from ${1, ...,
    Delta + 1}$ independently and uniformly at random. Then with high probability
  there exists a proper $(Delta + 1)$-colouring of $G$ in which the colour for
  every vertex $v$ is chosen from $L(v)$.
]

With this, we can construct a simple semi-streaming algorithm:

+ For every vertex $v in V$, sample $L(v)$.
+ During the stream, only store edges $(u, v)$ such that $L(u) inter L(v) != wideemptyset$.
+ Use @thm:pst[-] to colour the resulting graph.

In 2025, Assadi and Yazdanyar @Assadi_2026 went on to prove the following:

#theorem(<thm:apst>)[Asymmetric Palette Sparsification Theorem][
  For any graph $G = (V, E)$ with maximum degree $Delta$, there is a
  distribution on list-sizes $ell: V -> NN$ (depending only on vertices $V$ and
  not edges $E$) such that an average list size is $O(log^2 (𝑛))$ and the
  following holds. With high probability, if we sample $ell(v)$ colors $L(v)$
  for each vertex $v in V$ independently and uniformly at random from colors
  ${1, 2, ..., Delta + 1}$, then, with high probability, the greedy coloring
  algorithm that processes vertices in some fixed order (determined by vertex
  degrees and list sizes) finds a proper coloring of $G$ by coloring each $v$
  from its own list $L(v)$.
]

With this, we can improve upon our previous algorithm, by sampling $L(v)$ using
this new method. The advantage of this is the resulting graph can be coloured
_greedily_, making the algorithm much simpler.

We are interested in testing this algorithm in practice, and evaluating its
performance on real-life graphs.

== Our contributions

We present high-performance implementations of the greedy algorithm, the
Asymmetric Palette Sparsification (APS) algorithm, and a third algorithm
called the partitioning algorithm, with less theoretical guarantees but works
well in practice.

We find that:

- The APS algorithm is able to produce colourings of a similar quality to the
  greedy algorithm, while using less memory.
- However, the partitioning algorithm, in general, performs better than the
  APS algorithm in terms of memory and colouring quality. It is also faster
  than the greedy algorithm.

= Prerequisites

It is useful to be able to provide an upper bound on the probability that a
random variable deviates from its expected value by some amount, usually with
the aim of showing that this deviation does not happen with high probability.
Such a bound is called a concentration inequality, and while we omit common
such inequalities like Markov's inequality and Chebyshev's inequality, we state
and prove some other useful bounds.

#definition[
  A *Chernoff bound* for a random variable $X$ is a concentration inequality
  obtained by applying Markov's inequality to $e^(u X)$ (for some $u in RR$).

  For $u >= 0$, we obtain the following for all $a in RR$:

  $ Pr(X >= a) = Pr(e^(u X) >= e^(u a)) <= EE[e^(u X)] e^(-u a) $

  Similarly, for $u <= 0$:

  $ Pr(X <= a) = Pr(e^(u X) >= e^(u a)) <= EE[e^(u X)] e^(-u a) $

  For a specific random variable, we generally substitute an explicit form for
  the moment generating function $EE[e^(u X)]$, and then find the value of $u$
  that minimises the resulting expression.
]

#proposition(<prop:chernoff>)[
  Let $X ~ B(n, p)$. Then for $t >= 0$:

  $
    & Pr(X <= EE[X] - t) <= exp(- (t^2) / (2 EE[X])), \
    & Pr(X >= EE[X] + t) <= exp(- (t^2) / (2 (EE[X] + frac(t, 3, style: "horizontal")))).
  $
]

#proof[
  Define, for $x >= -1$:

  $
    phi(x) := (1 + x) log(1 + x) - x.
  $

  We apply the Chernoff bound to $X$: for all $u >= 0$

  $
    Pr(X <= EE[X] - t) <= EE[e^(u X)] e^(-u (EE[X] - t))
    = (1 - p + p e^u)^n e^(-u (EE[X] - t)).
  $

  For $t <= EE[X]$ (when $t > EE[X]$, the probability is 0, and the bound
  holds), we choose $u$ such that:

  $ e^u = ((EE[X] - t) (1 - p)) / (p (n - EE[X] + t)). $

  So, since $EE[X] = n p$:

  $
    Pr(X <= EE[X] - t) & <=
    ((p (n - EE[X] + t)) / ((EE[X] - t) (1 - p)))^(EE[X] - t) (1 - p + ((EE[X] - t) (1 - p)) / (n - EE[X] + t))^n \
    & <= (EE[X] / (EE[X] - t))^(EE[X] - t) ((n - EE[X]) / (n - EE[X] + t))^(n + EE[X] - t) \
    & = exp((EE[X] - t) ln(EE[X] / (EE[X] - t)) + (n - EE[X] + t) ln ((n - EE[X]) / (n - EE[X] + t)) + t - t) \
    & = exp(- EE[X] phi((-t) / EE[X]) - (n - EE[X]) phi(t / (n - EE[X]))) \
    & <= exp(- EE[X] phi((-t) / EE[X])).
  $

  Note that since $phi(0) = 0$ and $phi'(x) = log(1 + x) < x$,
  $phi(x) >= frac((x^2), 2, style: "horizontal")$ for $-1 <= x <= 0$, and so:

  $ Pr(X <= EE[X] - t) <= exp(- (t^2) / (2 EE[X])). $

  By a similar argument, for $t <= n - k$ (again, when $t > n - k$,
  $Pr(X >= EE[X] + t)$ is 0 and so the bound holds) we get:

  $
    Pr(X >= EE[X] + t) <= exp(- EE[X] phi(t / EE[X])).
  $

  Note that $phi(0) = phi'(0) = 0$, and:

  $
    phi''(x) = 1/(1 + x) >= 1 / (1 + x/3)^3 = ((x^2) / (2 (1 + x / 3)))''.
  $

  Therefore,

  $ phi(x) >= (x^2) / (2 (1 + x/3)). $

  This gives us:

  $
    Pr(X <= EE[X] + t) <= exp(- (t^2) / (2 (EE[X] + frac(t, 3, style: "horizontal")))).
  $
]

#proposition(<prop:bernchernoff>)[
  Let $X = sum_(i = 1)^n X_i$ for $X_i ~ "Be"(p_i)$ independent. Then for
  $t >= 0$:

  $ Pr(X >= EE[X] + t) <= exp(- (t^2) / (2 (EE[X] + frac(t, 3, style: "horizontal")))). $
]

#proof[
  Let $Y ~ B(n, frac(EE[X], n, style: "horizontal"))$ with $EE[X] = sum_(i = 1)^n p_i$.

  So, for all $u in RR$:

  $
    EE[e^(u X)] = product_(i = 1)^n (1 + p_i (e^u - 1)).
  $

  Taking the logarithm, and using Jensen's inequality (since $e^u$ is convex):

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
    <= EE[E^(u Y)] e^(-u (EE[Y] + t)).
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

#proposition(<prop:hypergeometric>)[#cite(<janson2000random>, form: "prose", supplement: "Theorem 2.10")][
  Let $X ~ "Hypergeometric"(N, K, n)$. Then for all $t >= 0$:

  $ Pr(X <= EE[X] - t) <= exp(-(t^2) / (2 EE[X])). $
]

#proof[
  Let $Y ~ B(n, frac(m, N, style: "horizontal"))$ (note then that
  $EE[X] = EE[Y]$). Since $e^x$ is convex (#cite(<hoeffding>, form: "prose", supplement: "Theorem 4")), we have that for all $u in RR$:

  $ EE[e^(u X)] <= EE[e^(u Y)]. $

  So, applying the Chernoff bound to $X$, for all $u <= 0, t >= 0$:

  $
    Pr(X <= EE[X] - t)
    <= e^(-u(EE[X] - t)) EE[e^(u X)]
    <= e^(- u (EE[Y] - t)) EE[e^(u Y)].
  $

  Therefore, we can use the bound proved in @prop:chernoff[-]:

  $ Pr(X <= EE[X] - t) <= exp(- (t^2) / (2 EE[Y])) = exp(- (t^2) / (2 EE[X])). $
]

= Algorithms

== The Greedy Algorithm

#let greedy = text(font: "New Computer Modern Sans")[greedy]

The Greedy Algorithm (henceforth called #greedy) is defined as follows:

+ Iterate through the vertices in any fixed order.
+ For each vertex, assign it the smallest colour that has not been assigned to
  any of its neighbours.

It is not hard to see that this finds a $(Delta + 1)$-colouring for any graph.
However, while it does work well in some streaming contexts (e.g. vertex
streaming), the greedy algorithm is not a semi-streaming algorithm since it
requires $Omega(n^2)$ space.

== The Asymmetric Palette Sparsification (APS) Algorithm

The APS algorithm is defined as follows:

+ Uniformly sample a random permutation $pi: V -> [n]$.
+ Define the *list size* of a vertex
  $ ell(v) = min(Delta + 1, (40 n ln n) / pi(v)). $
  For each $v in V$ let the *palette* $L(v)$ be uniformly sampled from
  $[Delta + 1]$ such that $|L(v)| = ell(v)$. Let $cal(L) = {L(v) | v in V}$.
+ Let the conflict graph $G_cal(L) = (V, E_cal(L))$ be the subgraph of $G$
  with all edges $(u, v) in E$ such that $L(u) inter L(v) != wideemptyset$.
  During the stream, only store edges in $G_cal(L)$.
+ Finally, run #greedy on $G_cal(L)$ (where each node can only use the colours
  in its palette $𝐿(𝑣)$) in decreasing order of $pi(v)$, and return the
  resulting colouring.

We present a proof that this algorithm is theoretically sound (i.e. it finds a
$(Delta + 1)$-colouring of $G$ with high probability and $tilde(O)(n)$ expected
space).

#lemma(<lemma:listsizes>)[List sizes][
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

#lemma(<lemma:degreebound>)[
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
  since $pi(v)$ is chosen uniformly, we can view $deg_pi^<(v)$ as a
  hypergeometric random variable, where $deg(v)$ vertices are sampled without
  replacement from $n - 1$ total nodes, and a vertex is "good" if
  $pi(u) < pi(v)$ (so there are $pi(v) - 1$ "good" vertices in $V without {v}$).

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
  *List sizes* follows immediately from @lemma:listsizes.

  For *Colourability*, let $v in V$. Let the set of *available colours*
  $A(v) subset.eq [Delta + 1]$ be the colours that have not yet been assigned
  to a neighbour of $v$ by the time we reach $v$ in the greedy step.

  Once again, we assume that $ell(v) < deg(v) + 1$, since otherwise by our
  earlier observation we can always assign $v$ a colour, and so the claim
  holds. So:

  $ pi(v) > (40 n ln n) / (deg(v) + 1). $

  Now, fix $pi$, and fix $L(u)$ for all vertices, $u$ coloured before $v$ by
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
    &= (binom(|A(v)|, 0) binom(Delta + 1 - |A(v)|, ell(v))) / binom(Delta + 1, ell(v))
    = (Delta + 1 - |A(v)|)! / (Delta + 1 - |A(v)| - ell(v))! dot (Delta + 1 - ell(v))! / (Delta + 1)! \
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
                                <= exp(-10 ln n) = n^(-10).
  $

  Finally, using a union bound over all vertices:

  $
    Pr(exists v in V med L(v) inter A(v) = wideemptyset)
    <= sum_(v in V) Pr(|L(v) inter A(v)| = 0)
    = n dot n^(-10) = n^(-9).
  $
]

We observe that a colouring of the conflict graph $G_cal(L)$ using the palettes
of each vertex is a colouring of the original graph $G$, since edges in $E
without E_cal(L)$ are between nodes with disjoint palettes. With this, we can
conclude that the algorithm produces a valid $(Delta + 1)$-colouring of $G$.

It remains to bound the memory of the algorithm.

#theorem[With high probability, the algorithm uses $tilde(O)(n)$ space.]

#proof[
  By @lemma:listsizes[-], we know that $cal(L)$ contains $O(n log^2(n))$ colours.

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
  particular, we can partition $E$ into $(Delta + 1)$ matchings
  $E_1, E_2, ... E_(Delta + 1)$. Within a given matching $E_i$, since no two
  edges are adjacent, each $I_(u, v)$ is independent.

  For a given matching $E_i$, let $X_i = sum_((u, v) in E_i) I_(u, v)$ be the
  number of edges in $E_i inter E_cal(L)$.

  So, since $|E_i| <= n$:

  $
    EE[X_i] = sum_((u, v) in E_i) EE[I_(u, v)]
    = |E_i| (2000 ln^4(n)) / (Delta + 1)
    <= (2000 n ln^4(n)) / (Delta + 1).
  $

  And so, applying @prop:bernchernoff[-] with
  $t = frac(2000 n ln^4(n), (Delta + 1), style: "horizontal")$ (so that
  $EE[X_i] <= t$):

  $
    Pr(X_i >= EE[X_i] + t) & <= exp(- (t^2) / (2 (EE[X_i] + frac(t, 3, style: "horizontal"))))
                             <= exp(- t / 4) \
                           & = exp(- (500 n ln^4(n)) / (Delta + 1))
                             <= exp(- 4 ln(n)) = n^(-4).
  $

  Then, using a union bound over all $Delta + 1$ matchings:

  $
    Pr(exists i med X_i >= EE[X] + t)
    <= sum_(i = 1)^(Delta + 1) Pr(X_i >= EE[X] + t)
    = (Delta + 1) n^(-4) <= n^(-3).
  $

  So, with high probability, for each matching $E_i$,
  $ |E_i inter E_cal(L)| = X_i <= EE[X_i] + t <= (4000 n ln^4(n)) / (Delta + 1). $

  Finally:

  $
    |E_cal(L)| = sum_(i = 1)^(Delta + 1) |E_i inter E_cal(L)|
    <= 4000 n ln^4(n) = O(n log^4(n)).
  $

  So the total space used by the algorithm is:

  $
    n + O(n log^2(n)) + O(n log^4(n)) = tilde(O)(n).
  $
]

== The Partitioning Algorithm

The partitioning algorithm is a simpler algorithm that performs well in
practice:

+ Let $m = frac(Delta, ln n, style: "horizontal")$. Partition $V$ using uniform
  sampling into equally sized sets $(V_1, V_2, ..., V_m)$.
+ During the stream, only store edges contained in $G[V_i]$ for some $i$.
+ Colour each $G[V_i]$ separately, and combine the results into a single
  colouring (where the colours used by each subgraph are disjoint).

Note that this is equivalent to the Palette Sparsification Algorithm, but with:

$ L(v) = {((i - 1) Delta) / m, ..., (i Delta) / m - 1} quad "for" v in V_i. $

#theorem[With high probability, the partitioning algorithm uses $tilde(O)(n)$ space.]

#proof[
  Let $E'$ be the edges stored by the algorithm.

  Since the partitions are chosen uniformly, given an edge $(u, v) in E$,

  $ Pr((u, v) in E') = Pr(exists i med u in V_i and v in V_i) = (ln n) / Delta. $

  So:

  $ |E'| ~ B(|E|, (ln n) / Delta). $

  And, since there at most $n Delta$ edges:

  $ EE[ |E'| ] = |E| (ln n) / Delta <= n ln n. $

  Using @prop:chernoff[-] with $t = 4 n ln n$:

  $
    Pr(X >= EE[X] + 4 n ln n) <= exp(- (4 n ln n)^2 / (2 (EE[X] + frac((4 n ln n), 3, style: "horizontal"))))
    <= exp(- 4 n ln n) <= n^(-4).
  $

  So, with high probability:

  $ |E'| <= EE[ |E'| ] + 4 n ln n <= 5 n ln n = tilde(O)(n). $
]

To finish this section, we will show that the partitioning algorithm does not
guarantee a $(Delta + 1)$-colouring on all graphs:

#theorem(<thm:partition>)[
  Let $G = (V, E)$ be an $n$-vertex graph made up of $sqrt(n)$ disconnected
  cliques (so that $Delta = sqrt(n) - 1$). Then the partitioning algorithm
  finds a colouring of size at least $1.5 Delta$ with high probability.
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
  Since $V_i$ is sampled uniformly, and each clique is of size
  $sqrt(n) = Delta + 1$,

  $ X_(i,K) ~ "Hypergeometric"(n, n / m, sqrt(n)). $

  So:

  $
    Pr(X_(i,K) >= x) >= Pr(X_(i,K) = x)
    & = (binom(n / m, x) binom(n - n / m, sqrt(n) - x)) / binom(n, sqrt(n)) \
    &= ((n/m) ... (n/m - x + 1)) / x! dot ((n - n/m) ... (n - n/m - sqrt(n) + x + 1)) / (sqrt(n) - x)! dot (sqrt(n))! / (n ... (n - sqrt(n) + 1)) \
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
  Let $cal(K) = {K}$ be the set of cliques in $G$. Let $p = Pr(X_(i,K) >= 2 ln
  n)$ (by @lemma:singlepartition, this is at least $n^(-0.4)$). For each $K
  in cal(K)$, let $I_(i,K)$ be an indicator variable that is 1 if $X_(i,K) >= 2 ln n$,
  and 0 otherwise. Let $Y_i = sum_(K in cal(K)) I_(i,K)$.

  By linearity of expectation:

  $ EE[Y_i] = sum_(K in cal(K)) EE[I_(i,K)] = p sqrt(n). $

  Intuitively, since a vertex from a given clique $K$ being assigned to $V_i$
  means that vertices from the other cliques are less likely to be assigned to
  $V_i$, as there is one less space, we can deduce that $Pr(Y_i = 0)$ is less
  than the equivalent probability were the $I_(i,K)$ variables independent:
  (to see this formally, we can use the fact that $(X_K)_(K in cal(K))$ forms a
  multivariate hypergeometric distribution, and so the random variables are
  _negatively associated_ @negativeassociation, meaning that since each
  $I_(i, K)$ is a monotonic transformation of $X_(i, K)$, they are negatively
  associated as well).

  $ Pr(Y_i = 0) <= (1 - p)^(sqrt(n)). $

  To see this more formally, we can use the fact that $(X_K)_(K in cal(K))$
  forms a multivariate hypergeometric distribution, and so the random variables
  are _negatively associated_ @negativeassociation, meaning that since each
  $I_(i, K)$ is a monotonic transformation of $X_(i, K)$, they are negatively
  associated as well @Wajc2017NegativeA. The above statement follows from a
  property of negatively associated random variables @Wajc2017NegativeA.

  Using $(1 - x)^r <= e^(-x r)$:

  $
    Pr(Y_i = 0) <= exp(- p sqrt(n)) <= exp(- n^(-0.4) dot n^(0.5))
      = exp(- n^(0.1)).
  $

  // Since the sizes of each $X_K$ are negatively correlated (in particular,
  // $(X_K)_(K in cal(K))$ forms a multivariate hypergeometric distribution, and
  // so for $K != J in cal(K), "Cov"(X_K, X_J) <= 0$),
  //
  // $
  //   "Var"(Y) = sum_(K in cal(K)) "Var"(I_K) + sum_(K != J in cal(K)) "Cov"(I_K, I_J)
  //   <= sum_(K in cal(K)) "Var"(I_K) = p (1 - p) sqrt(n).
  // $
  //
  // Using Chebyshev's inequality:
  //
  // $
  //   Pr(Y = 0) <= Pr(|Y - EE[Y]| >= EE[Y]) <= "Var"(Y) / EE[Y]^2
  //   <= (p (1 - p) sqrt(n)) / (p sqrt(n))^2 = (1 - p) / (p sqrt(n))
  //   <= 1 / (p n^(0.5)) <= n^(-0.1).
  // $
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
  probability:

  $
    C >= m dot 2 ln n = 2 Delta.
  $

  // Let $C$ be the total number of colours used by the algorithm. Let $Z$ be the
  // number of partitions $V_i$ that can be coloured with fewer than $2 ln n$
  // colours. By @lemma:singleclique, the probability of this happening for a
  // particular partition is less than $n^(-0.1)$ , and so by linearity of
  // expectation:
  //
  // $ EE[Z] < m n^(-0.1). $
  //
  // Using Markov's inequality:
  //
  // $ Pr(Z >= 0.1 m) <= EE[Z] / (0.1 m) < (m n^(0.1)) / (0.1 m) = 10 n^(-0.1). $
  //
  // This means that with high probability, fewer than 10% of the partitions can
  // be coloured using fewer than $2 ln n$ colours. Therefore:
  //
  // $ C >= (0.9 m) (2 ln n) > 1.5 Delta. $
]

= In practice

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
  space.

The advantage of both is that they avoid unnecessary copies into an
intermediary buffer. For both approaches, numbers are then parsed using
`std::from_chars()`, which is fast, non-allocating and locale-independent.

The two methods were tested by parsing a large graph file containing around 1M
edges. The results are shown in TODO. We compare the two approaches to the
original, "naive" approach (using `std::ifstream` and `>>`), and conclude that
while both are significantly faster than the naive approach, the `mmap` method
is slightly faster and more consistent overall.

== Storing graphs

Graphs are stored in adjacency list format, since only neighbourhood queries
are needed. All three algorithms result in a final greedy step, so we optimise
slightly by, for each vertex $v$, only storing the neighbours of $v$ that are
processed before it in the greedy step (since the neighbours processed after
$v$ will not have been assigned a colour when $v$ is processed). This allows us
to use half the storage we normally would.

== The Greedy Algorithm

The most computationally expensive part of the greedy algorithm (besides
reading) is finding the first available colour for a vertex $v$. The usual
approach is to store an array of booleans, where the ith entry is true if
the ith colour is taken by one of $v$'s neighbours, and false otherwise. The
first available colour is then the first entry that is false.

We experimented with using a bitset instead, and using gcc's `__builtin_ctzl`
to find the first available colour. However, this was not found to be faster
(see TODO).

== The Asymmetric Palette Sparsification (APS) Algorithm

The following changes were made to the APS algorithm:

- The initial step of the algorithm, shuffling the vertices, is mainly done
  to make sure adversarial graphs cannot break the algorithm. In practice, we
  do not expect real-world graphs to be adversarial, and this step did not
  result in better quality colourings, so it was removed (essentially letting
  $pi(v_i) = i$ for all $v in V$). This resulted in slightly reduced memory
  usage (since we do not have to store the permutation) and an increase in
  performance (since the greedy step can iterate through vertices in order,
  which is better for cache).
- The stated formula for $ell(v)$ resulted in a very small proportion of
  edges being skipped, even on very large graphs. We tested a handful of
  potential functions for $ell$, and settled on $ell(v) = c dot pi(v)^(-x)$,
  where $c$ and $x$ are parameters to the algorithm.
- On real graphs, it was often found that the greedy algorithm often found
  colouring several orders of magnitude smaller than $Delta + 1$. However, due
  to the nature of the APS algorithm (recall that palettes are sampled
  randomly from $[Delta + 1]$), it will not usually produce colourings smaller
  than $Delta + 1$. For this reason, we replace $Delta + 1$ with a parameter,
  which we call `max_colours`.

Depending on the values of $c$, $x$, and `max_colours`, the APS algorithm is
sometimes unable to assign each vertex a colour from its palette. Instead, if
the greedy step is unable to find a colour for $v$ from its palette, we assign
it a new, globally unique colour.

== The Partitioning Algorithm

The following changes were made to the partitioning algorithm:

- Instead of fixing $m = frac(Delta, ln n, style: "horizontal")$, we treat $m$
  as a parameter to the algorithm.
- Instead of sampling $(V_1, ..., V_m)$ randomly, with the same justification
  as for abandoning the shuffling step in the APS algorithm, we pick the
  partitions deterministically ($v_i in V_j <=> i equiv j (mod m)$).

== A Second Pass

We experiment with giving each algorithm a second pass over the edge stream,
with the aim of improving colouring quality and memory use at the cost of time.

=== The Greedy Algorithm

The greedy algorithm does not stand to gain much from a second pass, since it
loads the entire graph into memory. However, we explored using an initial pass
to record the degree of each node. This allows us to allocate the neighbour
list of each vertex in advance. In fact, it allows us to store the graph in
Compressed Sparse Row (CSR) format, where the neighbours of every vertex are
stored in a single, flat array. This is much more memory and time-efficient.

=== The APS Algorithm

We noticed that the APS algorithm, with well-chosen values of $c$, $x$ and
`max_colours`, is often able to assign almost every vertex a colour from its
palette. However, since uncoloured vertices are assigned a globally unique
colour, even a small number of uncoloured vertices can result in a much larger
colouring.

With this in mind, we instead do not give these nodes a colour during the first
pass. Call the set of uncoloured vertices $U$. Then the second pass is defined
as follows:

+ During the stream, only store edges in $G[U]$.
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
+ Use the greedy algorithm to find a colouring of $H$ (call it $psi$).
+ Return the combined colouring $(psi compose phi)$.

Note that in general, $|E_H| != tilde(O)(n)$ - consider a clique, in which
case $G tilde.equiv H$.

= Experiments

= Conclusion
<chap:conclusion>

The concluding chapter ideally consists of three parts:

+ Re-summarise the main contributions and achievements.
+ State the current project status and evaluate what was achieved with respect
  to the initial aims and objectives.
+ Outline open problems or future plans.

// ─────────────────────────────────────────────────────────────────────────────
// BACK MATTER — Bibliography
// ─────────────────────────────────────────────────────────────────────────────

#counter(heading).update(0)

#pagebreak()
#show bibliography: set heading(outlined: false)
#bibliography("dissertation.bib", style: "ieee")
// If you do not have a .bib file yet, comment out the line above and use:
// = References
// (then list references manually)

// ─────────────────────────────────────────────────────────────────────────────
// APPENDICES
// ─────────────────────────────────────────────────────────────────────────────

#pagebreak()
#heading(numbering: none, outlined: false)[Appendices]

#set heading(numbering: "A")
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

#text(weight: "bold")[This is a COMPULSORY Appendix]

List every prompt, tool, or reference used in the project and/or dissertation
with an Artificial Intelligence model. This includes Large Language Models
(LLMs) such as ChatGPT, image/video generation tools, or AI summarisation
tools.

#text(weight: "bold")[
  Failure to include this list can result in a Contract Cheating allegation.
]

// ── Appendix B: Example Appendix ─────────────────────────────────────────────
#pagebreak()
= Appendix B: Example Appendix
<appx:example>

Content which is not central to, but may enhance, the dissertation can be
included in one or more appendices; examples include:

- Lengthy mathematical proofs, numerical or graphical results summarised in
  the main body.
- Sample or example calculations.
- Results of user studies or questionnaires.

Note that the marking panel is not obliged to read appendices.
