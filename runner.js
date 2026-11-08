// Standalone WebGL2 multi-pass Shadertoy runner for Silk Waves.
// Renderer additions are separate from the original MIT-licensed shader source.
(() => {
  const canvas = document.getElementById('screen');
  const status = document.getElementById('status');
  const error = document.getElementById('error');
  const panel = document.getElementById('panel');
  const trigger = document.getElementById('panelTrigger');
  trigger.addEventListener('click',()=>{const open=panel.classList.toggle('open');trigger.setAttribute('aria-expanded',String(open));});
  const monthInput = document.getElementById('month');
  let selectedMonth = null; // null = system calendar; integer 0..11 = manually selected palette
  monthInput.addEventListener('change', () => {
    selectedMonth = monthInput.value === 'auto' ? null : Number(monthInput.value);
    markDirty();
  });
  const monthPicker = document.getElementById('monthPicker');
  const monthCurrent = document.getElementById('monthCurrent');
  const selectedSwatch = document.getElementById('selectedSwatch');
  const monthOptions = [...monthPicker.querySelectorAll('[data-month]')];
  function updateMonthPicker(){
    const active = monthOptions.find(button => button.dataset.month === monthInput.value);
    if (!active) return;
    monthCurrent.textContent = active.textContent.trim();
    selectedSwatch.style.background = getComputedStyle(active.querySelector('.month-swatch')).backgroundImage;
    monthOptions.forEach(button => button.setAttribute('aria-selected', String(button === active)));
  }
  monthOptions.forEach(button => button.addEventListener('click', () => {
    monthInput.value = button.dataset.month;
    monthInput.dispatchEvent(new Event('change'));
    updateMonthPicker();
    monthPicker.open = false;
    monthPicker.querySelector('summary').focus({preventScroll:true});
  }));
  updateMonthPicker();
  // Completely hide the corner UI after mouse exit, while keeping keyboard and touch access.
  panel.addEventListener('pointerleave', event => {
    if (event.pointerType === 'mouse' || event.pointerType === 'pen') {
      panel.classList.remove('open');
      monthPicker.open = false;
      trigger.setAttribute('aria-expanded', 'false');
      if (panel.contains(document.activeElement)) document.activeElement.blur();
    }
  });
  document.addEventListener('pointerdown', event => {
    if (!panel.contains(event.target)) {
      panel.classList.remove('open');
      monthPicker.open = false;
      trigger.setAttribute('aria-expanded', 'false');
    }
  });
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape') {
      panel.classList.remove('open');
      monthPicker.open = false;
      trigger.setAttribute('aria-expanded', 'false');
      if (panel.contains(document.activeElement)) document.activeElement.blur();
    }
  });

  const pauseInput = document.getElementById('pause');
  const resolutionInput = document.getElementById('resolution');
  const fpsInput = document.getElementById('frameRate');
  const fpsLabel = document.getElementById('fpsLabel');
  const lightingInput = document.getElementById('lighting');
  function dateUniform(){
    const now = new Date();
    const currentSeconds = now.getHours()*3600 + now.getMinutes()*60 + now.getSeconds() + now.getMilliseconds()/1000;
    const seconds = lightingInput.value === 'day' ? 12*3600 : lightingInput.value === 'dusk' ? 18*3600 : lightingInput.value === 'night' ? 0 : currentSeconds;
    return [now.getFullYear(),selectedMonth === null ? now.getMonth() : selectedMonth,selectedMonth === null ? now.getDate() : 1,seconds];
  }
  const resetInput = document.getElementById('reset');
  const common = window.SILK_SOURCES.Common;
  const shaders = window.SILK_SOURCES;
  const gl = canvas.getContext('webgl2', { alpha: false, antialias: false, depth: false, stencil: false, preserveDrawingBuffer: false, powerPreference: 'high-performance' });
  function fail(message){status.textContent=message;error.textContent=message;error.classList.add('visible');}
  if (!gl) { fail('WebGL2 is required. Try current Chrome, Firefox, or Edge.'); return; }
  if (!gl.getExtension('EXT_color_buffer_float')) { fail('Your GPU/browser does not support renderable floating-point textures (EXT_color_buffer_float).'); return; }
  const vertex = `#version 300 es\nprecision highp float;\nvoid main(){vec2 p=vec2((gl_VertexID<<1)&2,gl_VertexID&2);gl_Position=vec4(p*2.0-1.0,0.0,1.0);}`;
  const prelude = `#version 300 es
precision highp float;
precision highp int;
precision highp sampler2D;
uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iDate;
uniform vec4 iMouse;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

out vec4 _outColor;
`;
  const endings = {
    regular: `\nvoid main(){mainImage(_outColor,gl_FragCoord.xy);}\n`,
    image: `\nvoid main(){mainImage(_outColor,gl_FragCoord.xy);}\n`
  };
  function compile(type, src, label) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, src);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) throw Error(`${label}: ${gl.getShaderInfoLog(shader)}`);
    return shader;
  }
  const programs = {};
  try {
    const vs = compile(gl.VERTEX_SHADER, vertex, 'Vertex');
    for (const key of ['BufferA', 'BufferB', 'BufferC', 'BufferD', 'Image']) {
      const fs = compile(gl.FRAGMENT_SHADER, prelude + '\n' + common + '\n' + shaders[key] + (key === 'Image' ? endings.image : endings.regular), key);
      const p = gl.createProgram();
      gl.attachShader(p, vs); gl.attachShader(p, fs); gl.linkProgram(p);
      if (!gl.getProgramParameter(p, gl.LINK_STATUS)) throw Error(`${key}: ${gl.getProgramInfoLog(p)}`);
      gl.deleteShader(fs);
      programs[key] = {p, uniforms: Object.fromEntries(['iResolution','iTime','iTimeDelta','iFrame','iDate','iMouse',...Array.from({length:4},(_,i)=>'iChannel'+i)].map(k=>[k, gl.getUniformLocation(p,k)]))};
    }
    gl.deleteShader(vs);
  } catch(e) { fail('Shader compile error: '+e.message); console.error(e); return; }
  const vao = gl.createVertexArray(); gl.bindVertexArray(vao);
  const fb = gl.createFramebuffer();
  let W=480,H=270, buffers={}, indexA=0, indexD=0, simFrame=0, simTime=0, last=0, stopped=false;
  let dimensions={};
  let lastRender=0, lastStatus=0, fpsCount=0, measuredFPS=0, needsRedraw=true;
  // Once-per-frame values; don't create a new Date object for every shader pass.
  let frameDate=[0,0,0,0];
  function texture(w,h,linear=false) {
    const tex=gl.createTexture(); gl.bindTexture(gl.TEXTURE_2D,tex);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,linear?gl.LINEAR:gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,linear?gl.LINEAR:gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);
    gl.texImage2D(gl.TEXTURE_2D,0,linear?gl.RGBA16F:gl.RGBA32F,w,h,0,gl.RGBA,linear?gl.HALF_FLOAT:gl.FLOAT,null);
    return tex;
  }
  function clearTex(tex,w,h) {
    gl.bindFramebuffer(gl.FRAMEBUFFER, fb);
    gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.TEXTURE_2D,tex,0);
    if (gl.checkFramebufferStatus(gl.FRAMEBUFFER)!==gl.FRAMEBUFFER_COMPLETE) throw Error('Unsupported floating-point framebuffer format');
    gl.viewport(0,0,w,h); gl.clearColor(0,0,0,0); gl.clear(gl.COLOR_BUFFER_BIT);
  }
  function reset() {
    const native = resolutionInput.value === 'native';
    const aspect=Math.max(.25,Math.min(4,window.innerWidth/Math.max(1,window.innerHeight)));
    if (native) {
      // Render at the canvas's physical pixel density, not a fixed 4K ceiling.
      // This tracks display scaling and future high-resolution monitors.
      const dpr=window.devicePixelRatio || 1;
      W=Math.max(1,Math.round(window.innerWidth*dpr));
      H=Math.max(1,Math.round(window.innerHeight*dpr));
    } else {
      const limit=Number(resolutionInput.value);
      H=Math.max(1,Math.min(limit,Math.round(3840/aspect)));
      W=Math.max(1,Math.round(H*aspect));
    }
    const maxTexture=gl.getParameter(gl.MAX_TEXTURE_SIZE);
    const maxViewport=gl.getParameter(gl.MAX_VIEWPORT_DIMS);
    if(W>maxTexture||H>maxTexture||W>maxViewport[0]||H>maxViewport[1])
      throw Error(`Render size ${W}×${H} exceeds this GPU/browser limit. Choose a lower resolution.`);
    canvas.width=W; canvas.height=H;
    for(const arr of Object.values(buffers)) for(const t of arr) gl.deleteTexture(t);
    const tileSize=Math.max(12,Math.floor(H/34+0.5));
    const cHeight=128*(H>=300?2:1)+8+Math.ceil(H/tileSize);
    dimensions={A:[64,173],B:[192,192],C:[W,cHeight],D:[W,H]};
    buffers={};
    for(const name of ['A','B','C','D']){
      const [tw,th]=dimensions[name];
      buffers[name]=Array.from({length:(name==='A'||name==='D')?2:1},()=>texture(tw,th,name==='D'));
      for(const tex of buffers[name])clearTex(tex,tw,th);
    }
    indexA=0;indexD=0;simFrame=0;simTime=0;last=0;lastRender=0;needsRedraw=true;
    status.textContent=`${W}×${H} · WebGL2 · initializing`;
    error.classList.remove('visible');
  }
  function draw(key, dest, sources, dt) {
    const pr=programs[key], u=pr.uniforms;
    gl.useProgram(pr.p);
    gl.bindFramebuffer(gl.FRAMEBUFFER,fb);
    gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.TEXTURE_2D,dest,0);
    const [targetW,targetH]=dimensions[key.replace('Buffer','')];
    gl.viewport(0,0,targetW,targetH);
    gl.uniform3f(u.iResolution,W,H,1); gl.uniform1f(u.iTime,simTime); gl.uniform1f(u.iTimeDelta,dt); gl.uniform1i(u.iFrame,simFrame);
    gl.uniform4fv(u.iDate,frameDate);
    gl.uniform4f(u.iMouse,0,0,0,0);
    for(let i=0;i<4;i++){ gl.activeTexture(gl.TEXTURE0+i);gl.bindTexture(gl.TEXTURE_2D,sources[i] || null);gl.uniform1i(u['iChannel'+i],i); }
    gl.drawArrays(gl.TRIANGLES,0,3);
  }
  function drawScreen() {
    const pr=programs.Image, u=pr.uniforms;
    gl.useProgram(pr.p);
    gl.bindFramebuffer(gl.FRAMEBUFFER,null); gl.viewport(0,0,W,H);
    gl.uniform3f(u.iResolution,W,H,1); gl.uniform1f(u.iTime,simTime);gl.uniform1f(u.iTimeDelta,0);gl.uniform1i(u.iFrame,simFrame);
    gl.uniform4fv(u.iDate,frameDate);gl.uniform4f(u.iMouse,0,0,0,0);
    const inputs=[buffers.A[indexA],buffers.B[0],buffers.C[0],buffers.D[indexD]];
    for(let i=0;i<4;i++){gl.activeTexture(gl.TEXTURE0+i);gl.bindTexture(gl.TEXTURE_2D,inputs[i]);gl.uniform1i(u['iChannel'+i],i);}
    gl.drawArrays(gl.TRIANGLES,0,3);
  }
  function frame(now) {
    if(stopped) return;
    requestAnimationFrame(frame);
    // Browsers may throttle hidden tabs anyway; skip GPU work explicitly.
    if(document.hidden) { last=0;lastRender=0;return; }
    // Uncapped submits on every browser animation frame; requestAnimationFrame
    // normally tracks the display refresh rate and may be browser-throttled.
    const cap = fpsInput.value === 'uncapped' ? 0 : Number(fpsInput.value);
    const interval = cap > 0 ? 1000 / cap : 0;
    if(interval && lastRender && now-lastRender < interval-1) return;
    if(pauseInput.checked && !needsRedraw) {last=0;return;}
    const dt=last?Math.min((now-last)/1000,0.133):1/60;
    last=now;lastRender=now;
    frameDate=dateUniform();
    if(!pauseInput.checked){
      simTime+=dt;
      // A and D read the previous frame of themselves, using separate ping-pong targets.
      const nextA=1-indexA;
      draw('BufferA',buffers.A[nextA],[buffers.A[indexA]],dt);indexA=nextA;
      draw('BufferB',buffers.B[0],[buffers.A[indexA]],dt);
      draw('BufferC',buffers.C[0],[buffers.B[0]],dt);
      const nextD=1-indexD;
      draw('BufferD',buffers.D[nextD],[buffers.C[0],buffers.D[indexD],buffers.A[indexA]],dt);indexD=nextD;
      simFrame++;
    }
    drawScreen(); needsRedraw=false;
    fpsCount++;
    if(!lastStatus)lastStatus=now;
    if(now-lastStatus>=1000){
      measuredFPS=Math.round(fpsCount*1000/(now-lastStatus));
      fpsCount=0;lastStatus=now;
      fpsLabel.textContent=`${measuredFPS} FPS`;
      status.textContent=`${W}×${H} · WebGL2 · ${measuredFPS} FPS · ${fpsInput.value === 'uncapped' ? 'uncapped (display/browser limited)' : 'cap '+fpsInput.value}`;
    }
  }
  // Redraw on color/time changes even when the simulation is paused.
  function markDirty(){ needsRedraw=true;last=0; }
  lightingInput.addEventListener('change',markDirty);
  fpsInput.addEventListener('change',()=>{lastRender=0;markDirty();});
  pauseInput.addEventListener('change',markDirty);
  document.addEventListener('visibilitychange',()=>{last=0;lastRender=0;markDirty();});
  function safeReset(){try{reset();}catch(e){stopped=true;fail('Cannot allocate this resolution: '+e.message);console.error(e);}}
  resolutionInput.addEventListener('change',()=>{const wasStopped=stopped;stopped=false;safeReset();if(wasStopped&&!stopped)requestAnimationFrame(frame);});
  resetInput.addEventListener('click',()=>{const wasStopped=stopped;stopped=false;safeReset();if(wasStopped&&!stopped)requestAnimationFrame(frame);});
  let resizeTimer;window.addEventListener('resize',()=>{clearTimeout(resizeTimer);resizeTimer=setTimeout(safeReset,250);});
  safeReset();if(!stopped)requestAnimationFrame(frame);
})();
