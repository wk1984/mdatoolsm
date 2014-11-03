function m = test_pls1(type, casen)
   clc
   close all

   if nargin < 1
      type = 'people';
   end
   
   if nargin < 2
      casen = 3;
   end
   
   switch type
      case 'people'
         ncomp = 3;
         d = load('people');
         oX = d.people(:, [2:12]);
         oy = d.people(:, 1);
         info = 'Model for People data';   
         factorCols = {'Sex', 'Region'};
         factorLevels = { {'Male', 'Female'}, {'A', 'B'} };
         excludedCols = {'Income'};
         excludedRows = 1:8:32;
         cind = true(oX.nRows, 1);
         cind(1:4:end) = false;         
         scale = 'on';
         center = 'on';
         p = prep();
      case 'spectra'
         ncomp = 4;
         d = load('simdata');
         oX = d.spectra;
         oy = d.conc(:, 3);
         info = 'Model for UV/Vis spectra (simdata)';
         factorCols = {};
         factorLevels = {};
         scale = 'off';
         center = 'on';
         excludedCols = 1:20;
         excludedRows = 1:5:150;
         cind = true(oX.nRows, 1);
         cind(101:150) = false;  
         p = prep();
   end      
   
   exR = false(oX.nRows, 1);
   exR(excludedRows) = true;
   excludedRows = exR;
         
   switch casen
      case 1
         fprintf('1. Testing simple model\n')   
         X = copy(oX);
         y = copy(oy);

         m = mdapls(X, y, ncomp, 'Center', center, 'Scale', scale);
         m.info = info;   
         summary(m.calres)   
         %showPlotsForResult(m.calres);
         showPlotsForModel(m);
      
      case 2
         fprintf('2. Testing data with excluded colums and rows\n')   
         X = copy(oX);
         y = copy(oy);
         for i = 1:numel(factorCols);
            X.factor(factorCols{i}, factorLevels{i});
         end
         X.excludecols(excludedCols);      
         X.excluderows(excludedRows);
         y.excluderows(excludedRows);

         m = mdapls(X, y, ncomp, 'Center', center, 'Scale', scale);
         m.info = info;

         summary(m);
         summary(m.calres);
         showPlotsForModel(m);   
         showPlotsForResult(m.calres);
   
      case 3
         fprintf('3. Test set validation\n')   
         X = copy(oX);
         y = copy(oy);

         Xc = X(cind, :);
         yc = y(cind, :);

         Xt = X(~cind, :);
         yt = y(~cind, :);

         m = mdapls(Xc, yc, ncomp, 'TestSet', {Xt, yt}, 'Scale', scale);
         m.info = info;
         summary(m);
         summary(m.calres);
         summary(m.testres);
         showPlotsForResult(m.calres);
         showPlotsForResult(m.testres);
         showPlotsForModel(m, 'mcg');

      case 4
         fprintf('4. Cross-validation\n')   
         X = copy(oX);
         y = copy(oy);

         m = mdapls(X, y, ncomp, 'CV', {'rand', 8, 8}, 'Scale', scale);
         m.info = info;
         summary(m);
         summary(m.calres);
         summary(m.cvres);
         showPlotsForModel(m, 'mcg');
         showPlotsForResult(m.calres);
         showPlotsForResult(m.cvres);

      case 5
         fprintf('5. Test set and cross-validation for data with factors and hidden values\n')   
         X = copy(oX);
         y = copy(oy);
         for i = 1:numel(factorCols);
            X.factor(factorCols{i}, factorLevels{i});
         end
         X.excludecols(excludedCols);      

         Xc = X(cind, :);
         yc = y(cind, :);

         Xt = X(~cind, :);
         yt = y(~cind, :);

         Xc.excluderows(excludedRows(cind));
         yc.excluderows(excludedRows(cind));

         Xt.excluderows(excludedRows(~cind));
         yt.excluderows(excludedRows(~cind));

         m = mdapls(Xc, yc, ncomp, 'TestSet', {Xt, yt}, 'CV', {'rand', 8, 4}, 'Prep', {p, prep()}, 'Scale', scale);
         m.info = info;

         summary(m);
         summary(m.calres);
         summary(m.cvres);
         summary(m.testres);
         showPlotsForModel(m, 'mcg');
%         showPlotsForResult(m.calres);
%         showPlotsForResult(m.cvres);
%         showPlotsForResult(m.testres);
   end
end

function showPlotsForModel(m, col)
   if nargin < 2
      col = 'r';
   end
   
   summary(m)
   
   % overview plot
   figure('Name', 'Model overview')
   plot(m)

   % prediction and regcoeffs plots
   figure('Name', 'Model: predictions')
   subplot(2, 2, 1)
   plotpredictions(m);   
   subplot(2, 2, 2)
   plotpredictions(m, 1, 'Labels', 'names', 'ShowExcluded', 'on');
   subplot(2, 2, 3)
   plotpredictions(m, 1, 1);   
   subplot(2, 2, 4)
   plotpredictions(m, 2, 'Labels', 'names', 'ShowExcluded', 'on');
      
   figure('Name', 'Model: regression coefficients')
   subplot(2, 2, 1)
   plotregcoeffs(m);
   subplot(2, 2, 2)
   plotregcoeffs(m, 1,'Type', 'line');
   subplot(2, 2, 3)
   plotregcoeffs(m, 1, 2, 'Type', 'line');
   subplot(2, 2, 4)
   plotregcoeffs(m, 1, 'Type', 'bar', 'Labels', 'names', 'CI', 'off');

   figure('Name', 'Model: Y residuals')
   subplot(2, 2, 1)
   plotyresiduals(m);
   subplot(2, 2, 2)
   plotyresiduals(m, 1, 'Labels', 'names');
   subplot(2, 2, 1)
   plotyresiduals(m, 1, 2, 'Labels', 'names');
   subplot(2, 2, 2)
   plotyresiduals(m, 1, 'Labels', 'names', 'Color', col, 'ShowExcluded', 'on');

   % Scores
   figure('Name', 'Model: scores')
   subplot(2, 2, 1)
   plotxscores(m);
   subplot(2, 2, 2)
   plotxscores(m, [2 3], 'Labels', 'names', 'ShowExcluded', 'on');
   subplot(2, 2, 3)
   plotxyscores(m);
   subplot(2, 2, 4)
   plotxyscores(m, 1, 'Labels', 'names', 'ShowExcluded', 'on');
   
   % explained variance for X
   figure('Name', 'Model: explained variance for X')
   subplot(2, 2, 1)
   plotxexpvar(m);
   subplot(2, 2, 2)
   plotxexpvar(m, 'Type', 'bar');
   subplot(2, 2, 3)
   plotxcumexpvar(m);
   subplot(2, 2, 4)
   plotxcumexpvar(m, 'Type', 'bar');

   % explained variance for Y
   figure('Name', 'Model: explained variance for Y')
   subplot(2, 2, 1)
   plotyexpvar(m);
   subplot(2, 2, 2)
   plotyexpvar(m, 'Type', 'bar');
   subplot(2, 2, 3)
   plotycumexpvar(m);
   subplot(2, 2, 4)
   plotycumexpvar(m, 'Type', 'bar');
   
   % RMSE
   figure('Name', 'Model: RMSE and X residuals')
   subplot(2, 2, 1)
   plotrmse(m);
   subplot(2, 2, 2)
   plotrmse(m, 'Type', 'bar');
   subplot(2, 2, 3)
   plotxresiduals(m)
   subplot(2, 2, 4)
   plotxresiduals(m, 'Labels', 'names')

end

function showPlotsForResult(res)
   summary(res)
      
   % plot overview
   figure('Name', 'Result overview')
   plot(res)
      
   % prediction and regcoeffs plots
   figure('Name', 'Result: predictions and residuals')
   subplot(2, 2, 1)
   plotpredictions(res);
   subplot(2, 2, 2)
   plotpredictions(res, 'Labels', 'names', 'Colorby', res.ypred(:, 1, 1), 'ShowExcluded', 'on');
   subplot(2, 2, 3)
   plotyresiduals(res);
   subplot(2, 2, 4)
   plotyresiduals(res, 'Labels', 'names', 'ShowExcluded', 'on');

   % Scores
   figure('Name', 'Result: scores')
   subplot(2, 2, 1)
   plotxscores(res);
   subplot(2, 2, 2)
   plotxscores(res, [2 3], 'Labels', 'names', 'Colorby', res.ypred(:, 1, 1), 'ShowExcluded', 'on');
   subplot(2, 2, 3)
   plotxyscores(res);
   subplot(2, 2, 4)
   plotxyscores(res, 2, 'Labels', 'names', 'Colorby', res.ypred(:, 1, 1), 'ShowExcluded', 'on');
   
   % explained variance for X
   figure('Name', 'Result: explained variance for X')
   subplot(2, 2, 1)
   plotxexpvar(res);
   subplot(2, 2, 2)
   plotxexpvar(res, 'Type', 'bar', 'Labels', 'values', 'FaceColor', 'r');
   subplot(2, 2, 3)
   plotxcumexpvar(res);
   subplot(2, 2, 4)
   plotxcumexpvar(res, 'Type', 'bar', 'Labels', 'values', 'FaceColor', 'r');

   % explained variance for Y
   figure('Name', 'Result: explained variance for Y')
   subplot(2, 2, 1)
   plotyexpvar(res);
   subplot(2, 2, 2)
   plotyexpvar(res, 'Type', 'bar', 'Labels', 'values', 'FaceColor', 'r');
   subplot(2, 2, 3)
   plotycumexpvar(res);
   subplot(2, 2, 4)
   plotycumexpvar(res, 'Type', 'bar', 'Labels', 'values', 'FaceColor', 'r');
   
   % RMSE
   figure('Name', 'Result: RMSE and X residuals')
   subplot(2, 2, 1)
   plotrmse(res);
   subplot(2, 2, 2)
   plotrmse(res, 'Type', 'bar', 'Labels', 'values', 'FaceColor', 'r');
   subplot(2, 2, 3)
   plotxresiduals(res)
   subplot(2, 2, 4)
   plotxresiduals(res, 'Labels', 'names', 'Color', 'r')
   
end
