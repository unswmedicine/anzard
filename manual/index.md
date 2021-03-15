---
layout: page
title: ANZARD User Manual
---
{% include JB/setup %}

  <h2 id="anzard_data_submission_instructions">Data Submission</h2>
  <ul>
    <li><a href="/user_manual/pdfs/anzard_data_submission_instructions_v1.0_20Oct2020.pdf">Data Submission Instructions</a></li>
  </ul>
{% for category in site.categories %}
  <h2 id="{{ category[0] }}-ref">{{ category[0] | join: "/" }}</h2>
  <ul>
    {% assign pages_list = category[1] %}
    {% include JB/pages_list %}
  </ul>
{% endfor %}
