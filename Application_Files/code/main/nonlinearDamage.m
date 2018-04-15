Sf = 930.0;
b = -0.095;
a0 = 0.0;
alpha = 0.4;
enduranceLimit = 1e7;
forwardExtrapolation = 0.0;
extrapolationFactor = 0.05;

cycles = 188.3;

quotient = cycles./Sf;
lives = 0.5.*quotient.^(1.0/b);
Nf = lives;

linearLife = round(1.0/sum(1.0./lives));

D = 0.0;
n = 1.0;
Di = zeros(1.0, length(lives));

d_buffer = [];

if forwardExtrapolation == 1.0
    cyclesForward = round(extrapolationFactor*linearLife);
    if cyclesForward == 0.0
        cyclesForward = 1.0;
    end
else
    cyclesForward = 1.0;
end

index = 1.0;

timer = tic;
while D < 1
    Di = sum((1.0/0.18).*(a0 + (0.18 - a0).*((n./Nf).^((2.0/3.0).*Nf.^alpha))));
    
    Di = Di*cyclesForward;
    D = D + Di;
    n = n + cyclesForward;
    
    d_buffer(index) = D; %#ok<SAGROW>
    index = index + 1.0;
    
    if n > enduranceLimit
        break
    end
end

time = toc(timer);

if d_buffer(end) > 1.0
    d_buffer(end) = [];
    
    n = n - cyclesForward;
    index = index - 1.0;
end

n = n - 1.0;
index = index - 1.0;

nRatios = linspace(0.0, cyclesForward*index, index + 1.0);

P1 = plot(nRatios, [0.0, d_buffer], '-r');
hold on
P2 = plot([0.0, linearLife], [0.0, 1.0], '-g');
axis tight
legend([P1, P2], 'Nonlinear Life', 'Linear Life')

fprintf('Nonlinear Life = %.0f cycles\n', n)
fprintf('Linear Life = %.0f cycles\n', linearLife)
fprintf('Iterations = %.0f\n', index)
fprintf('Elapsed time = %fs\n', time)