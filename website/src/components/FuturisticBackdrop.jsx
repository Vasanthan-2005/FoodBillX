import React, { useEffect, useRef } from 'react';

export const FuturisticBackdrop = () => {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const prefersReduced =
      typeof window !== 'undefined' &&
      window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;

    let animationId;
    let width = (canvas.width = window.innerWidth);
    let height = (canvas.height = window.innerHeight);

    const handleResize = () => {
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    };
    window.addEventListener('resize', handleResize);

    const nodes = Array.from({ length: 42 }, (_, idx) => ({
      x: Math.random() * width,
      y: Math.random() * height,
      vx: (Math.random() - 0.5) * 0.45,
      vy: -0.15 - Math.random() * 0.35,
      r: 1.2 + Math.random() * 2.2,
      hue: idx % 3 === 0 ? '#22D3EE' : idx % 2 === 0 ? '#FF6D00' : '#FFB300',
      alpha: 0.25 + Math.random() * 0.45,
    }));

    const renderFrame = () => {
      ctx.clearRect(0, 0, width, height);

      // Draw subtle spatial grid lines
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.024)';
      ctx.lineWidth = 1;
      const step = 72;
      for (let x = 0; x < width; x += step) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, height);
        ctx.stroke();
      }
      for (let y = 0; y < height; y += step) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(width, y);
        ctx.stroke();
      }

      // Connect nearby luminous embers
      for (let i = 0; i < nodes.length; i++) {
        const a = nodes[i];
        if (!prefersReduced) {
          a.x += a.vx;
          a.y += a.vy;
          if (a.y < -10) a.y = height + 10;
          if (a.x < -10) a.x = width + 10;
          if (a.x > width + 10) a.x = -10;
        }

        ctx.beginPath();
        ctx.arc(a.x, a.y, a.r, 0, Math.PI * 2);
        ctx.fillStyle = a.hue;
        ctx.globalAlpha = a.alpha;
        ctx.fill();

        for (let j = i + 1; j < nodes.length; j++) {
          const b = nodes[j];
          const dx = a.x - b.x;
          const dy = a.y - b.y;
          const dist = Math.hypot(dx, dy);
          if (dist < 135) {
            ctx.beginPath();
            ctx.moveTo(a.x, a.y);
            ctx.lineTo(b.x, b.y);
            ctx.strokeStyle = dist % 2 > 1 ? '#FF6D00' : '#22D3EE';
            ctx.globalAlpha = (1 - dist / 135) * 0.12;
            ctx.stroke();
          }
        }
      }
      ctx.globalAlpha = 1;

      if (!prefersReduced) {
        animationId = window.requestAnimationFrame(renderFrame);
      }
    };

    renderFrame();
    return () => {
      window.removeEventListener('resize', handleResize);
      if (animationId) window.cancelAnimationFrame(animationId);
    };
  }, []);

  return (
    <div className="fixed inset-0 -z-10 overflow-hidden pointer-events-none">
      <div className="absolute -top-48 -left-32 w-[520px] h-[520px] rounded-full bg-[#FF6D00]/12 blur-[140px]" />
      <div className="absolute top-1/3 -right-40 w-[560px] h-[560px] rounded-full bg-cyan-500/10 blur-[150px]" />
      <div className="absolute -bottom-48 left-1/3 w-[480px] h-[480px] rounded-full bg-purple-600/10 blur-[140px]" />
      <canvas ref={canvasRef} className="w-full h-full opacity-90" />
    </div>
  );
};
