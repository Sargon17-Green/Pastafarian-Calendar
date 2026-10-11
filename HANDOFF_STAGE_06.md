# टप्पा 6 — DISCOVERY 03

मूळ 55-टप्प्यांच्या कंत्राटातील तिसरा दोष: `oldDistance(c,t)=abs(dayTag(c)-dayTag(t))`. `dayTag` हा टप्पा 5 मधील सुधारित tag आहे. नियमाधारित `distance=abs(t-c)+1`. `PATCH 03` हा फक्त टप्पा 7 मध्ये होणार आहे.

पाच साक्षी: `(F,F),(F-1,F),(F-2,F+2),(F+1,F+1),(F+1,F+2)`; चार `MISMATCH`, एक `MATCH`. इतर तपासण्या: 225 जोड्या, मोठे bigint, स्वतंत्र context आणि चुकीचे इनपुट.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154839676

या run मध्ये Stage 01–05 PASS, Stage 06 guards PASS, आणि तीन expected-red regression योग्यरीत्या पुष्टी झाले. पुढे टप्पा 7 — PATCH 03.
