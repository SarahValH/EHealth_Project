%E-health methods and applications
%Project- Part 1
%Laboratory 1
%Authors:CONTRINO Paolo, CRIPPA Dario, DORIZZA Andrea
%GONZÁLEZ Diana,ROZO Andrea, VALDERRAMA Sarah

clc
clear
close all

%Sets webread timeout up to 20 seconds (maximum for Windows 10 is 21 seconds)
options = weboptions('Timeout',20);
error = 0;
max_error = 3;
success = 0;

%_______________URL Variable declaration and reading______________%

app_store = 'https://itunes.apple.com/us/genre/ios/id36?mt=8'; 
root = 'https://itunes.apple.com/us/genre/';
categories = ["ios-medical", "ios-health-fitness"];
while(error <= max_error && ~success)
    try
        url_beginning = webread(app_store,options);
        success = 1;
    catch
        error = error+1;
    end
end
if(error > max_error)
    disp('It was not possible to connect with iTunes')
    return
end

%___Initialization of vector containing the alphabet characters___%

cont = 1;
ASCII = char(27);
for op = 65 : 90
    ASCII(cont) = char(op);
    cont = cont + 1;
end
ASCII(end+1) = char(42);   % #

% Initializes the result structure to be filled with the APPs information
app.URL = {};
app.name = {};
app.id = {};
app.category = {};

%__In each loop iteration extracts the Apps from each category_____%

for i = 1 : length(categories)       % from category 1 to the last
    for j = 1 : length(ASCII)
        t = extractBetween(url_beginning, categories(i), "?mt=8");  % Extracts the piece of URL of that category
        new_url = strcat(root, categories(i), t{1,1}, "?mt=8"); % Concatenates the root URL with the category URL
        new_url_let = strcat(new_url, "&letter=");
        band = 0;
        page = 0;
        bandcontrol_no_next = 0;
        cont_no_next = 1;
        % Control for pages
        while (band == 0)
            page = page + 1;
            strpage = string(page);
            new_url_letp = strcat(new_url_let, ASCII(j), "&page=", strpage, "#page");
            html_data_let = webread(new_url_letp,options);
            % Extracts from the html, the piece of text containing the applist
            txt_chunk = extractBetween(html_data_let, '<ul>', '</ul>');
            % Check if there's a paginate-more in the html which
            % indicates if there's a NEXT page, as once we are in the
            % last page there's no NEXT option in the pagination
            paginate_more = strfind(html_data_let, 'paginate-more">Next</a>');
            app_list_links = {};
            %Extracts from the piece of text, the app links and put them in an array
            for indxChunk = 1 : size(txt_chunk,1)
                app_list_links = [app_list_links; extractBetween(txt_chunk{indxChunk}, '<li>', '</li>')];
            end
            %Extracts from the links, the URL and put them in a struct array
            app_url = extractBetween(app_list_links, '<a href="', '">');
            app.URL = [app.URL; app_url];
            %Extracts from the links, the name and put them in a struct array
            app.name = [app.name; extractBetween(app_list_links, '">', '</a>')];
            %Extracts from the links, the id and put them a struct array
            app.id = [app.id; extractBetween(app_list_links, '/id', '?mt=8">')];
            %Saves the category of each app
            N = size(app_url, 1);
            app.category = [app.category; repmat({categories(i)}, N, 1)];
            if (isempty(paginate_more) == 1)
                if (page == 1)  % No Next in the pagination
                    bandcontrol_no_next = 1;
                    pagination_data = extractBetween(html_data_let, 'list paginate', '</a></li></ul>');
                    if (isempty(pagination_data))   % Control is just 1 page
                        band = 1;
                    else
                        uper_pag = pagination_data{1};
                        final_page = str2double(uper_pag(end));
                    end
                end
                if (bandcontrol_no_next == 1)
                    if(cont_no_next == final_page)
                        bandcontrol_no_next = 0;
                        band = 1;
                    else
                        cont_no_next  = cont_no_next + 1;
                    end
                else
                    band = 1;
                end
            end         
        end
    end
end

% Creates the datasets for each category
indxMedical = find(strcmp(categories(1), [app.category{:}]));
indxHF = find(strcmp(categories(2), [app.category{:}]));
% Medical dataset
M.URL = app.URL(indxMedical);
M.name = app.name(indxMedical);
M.id = app.id(indxMedical);
% Health and Fitness dataset
HnF.URL = app.URL(indxHF);
HnF.name = app.name(indxHF);
HnF.id = app.id(indxHF);

% Eliminates the duplicate apps
[uniqueM,indUM,indM] = unique(M.id,'stable');
[uniqueHnF,indUHF,indHF] = unique(HnF.id,'stable');
M.URL = M.URL(indUM);
M.id = M.id(indUM);
M.name = M.name(indUM);
HnF.URL = HnF.URL(indUHF);
HnF.id = HnF.id(indUHF);
HnF.name = HnF.name(indUHF);

[both,indm,indhf] = intersect(uniqueM,uniqueHnF,'stable');
catM = repmat("Medical",length(uniqueM),1);
catHF = repmat("Health and Fitness",length(uniqueHnF),1);
catM(indm) = "Both";
catHF(indhf) = [];

hnf = HnF;
hnf.URL(indhf) = [];
hnf.id(indhf) = [];
hnf.name(indhf) = [];

merged.URL = [M.URL;hnf.URL];
merged.id = [M.id;hnf.id];
merged.name = [M.name;hnf.name];
merged.category = [catM;catHF];

%%
%__________________Feature Extraction_____________________%

AppsFeatures = {};
notEnglish=0;
english="en";
indx_eng = [];
indx_error = [];
indx_feat = [];

vect=round((length(merged.URL)-1).*rand(20,1))+1; 
%vect is a vector containg random numbers, to extract the features for any 5 random apps in the list
% is the length of the app-1 because rand() generates random numbers from 0
% to 1, and since we don't want an index to be 0, we substract 1 to the
% length and add it at the end.

for i=1:length(vect)
    url = merged.URL(vect(i));
    error = 0;
    next = 0;
    success = 0;
    while(error <= max_error && ~success && ~next)
        try
            html_features= webread(url{:},options);% Reads the html code of the random app
            success = 1;
        catch ME
            error = error+1;
            if(isequal(ME.identifier,'MATLAB:webservices:HTTP404StatusCodeError'))
                next = 1;
                indx_error = [indx_error vect(i)];
            end
            if(error == max_error && ~next)
                next = 1;
                indx_error = [indx_error vect(i)];
            end
        end
    end
    
    % Since MetaMap works only with texts in English, we save only
    % those apps whose description is written in English.
    if(~next)
        temp_extract=extractBetween(html_features,'<div class="section__description">','</section>');
        % temporal chunck of code that allows to exctract the language from it
        description=extractBetween(temp_extract, '<p aria-label="', '" id=');
        if (~isempty(description))  % Validation of the existence of the feature
            Language=string(py.langdetect.detect(string(description{:})));
        end
        
        %Feature 1:  App ID
        features.id=merged.id(vect(i));
        % Since we already have this information it takes it from the variable app.id
        
        %Feature 2: App Name
        features.name=merged.name(vect(i));
        % Since we already have this information it takes it from the variable app.name
        
        %Feature 3: App URL
        features.URL=merged.URL(vect(i));
        % Since we already have this information it takes it from the variable app.URL
        
        %Feature 4: App Description (Unstructured text)
        features.description=description;
        
        %Feature5: Keywords
        temp_extract=extractBetween(html_features, '<meta name="keywords" content="','" id=');
        if(~isempty(temp_extract))  % Validation of the existence of the feature
            features.keywords=temp_extract;
        else
            features.keywords='NaN';
        end
        
        %Feature 6: Version
        temp_extract=extractBetween(html_features,'whats-new__latest__version">Version','</p>');
        if(~isempty(temp_extract))  % Validation of the existence of the feature
            features.version=temp_extract;
        else
            features.version='NaN';
        end
        
        %Feature 7: Age Rating
        temp_extract=extractBetween(html_features,'">Age Rating</dt>','<!---->');
        agerat=extractBetween(temp_extract,'large-6">','</dd>');
        if (~isempty(agerat))  % Validation of the existence of the feature
            agerat = agerat{:};
            nums = ['1','2','3','4','5','6','7','8','9','0','+'];
            indx = find(ismember(agerat,nums));
            if(~isempty(indx))
                agerat = agerat(indx(1):indx(end));
            end
            % temporal chunck of code that allows to exctract the age rating from it
            features.agerat=agerat;
        else
            features.agerat='NaN';
        end
        
        %Feature 8: Language
        temp_extract=extractBetween(html_features,'">Languages</dt>','</div>');
        % temporal chunck of code that allows to exctract the language from it
        temp_extract=extractBetween(temp_extract,'<dd aria-label="','" id="');
        if(~isempty(temp_extract))  % Validation of the existence of the feature
            features.language=temp_extract;
        else
            features.language='NaN';
        end
        
        %Feature 9-11: Developer ID- Developer Name- Developer Webside
        temp_extract=extractBetween(html_features,'<h2 class="product-header__identity app-header__identity">','</h2>');
        % temporal chunck of code that allows to exctract all features related to the developer from it
        if(~isempty(temp_extract))  % Validation of the existence of the feature
            features.developerid=extractBetween(temp_extract,'id','?mt=8"');
            features.developername=extractBetween(temp_extract,'?mt=8">','</a>');
            features.developerURL=extractBetween(temp_extract,' <a class="link" href="','">');
        else
            features.developerid='NaN';
            features.developername='NaN';
            features.developerURL='NaN';
        end
        
        %Feature 12: Category (medical, health and fitness, or both)
        features.category = merged.category(vect(i));
        % Since we already have this information it takes it from the variable app.category
        
        
        %Feature 13-14: Price (numbers only) and Currency
        temp_extract=extractBetween(html_features,'">Price</dt>','</div>');
        %temporal chunck of code that allows to exctract the price and currency from it
        temp_price=extractBetween(temp_extract,'<dd class="information-list__item__definition l-column medium-9 large-6">','</dd>');
        %temporal variable to save the price to the process it beacuse it may be a string saying "Free" or may have characters such as $,€,etc.
        if(isempty(temp_price))  % Validation of the existence of the feature
            features.price='NaN';
            features.pricecurrency='NaN';
        else
            temp_price = temp_price{:};
            if(isequal(temp_price,'Free'))
                features.pricecurrency='$';
                features.price=0;%if it is free the price is 0
                %if it is free the currency is USD by default
            else
                flag=false;
                temp_currency='$'; %temporal variable to manage the currency
                for j=1:length(temp_price)
                    if(flag==false)
                        if(temp_price(j)<char(48) || temp_price(j)>char(57))% meaning that is not a number, thus is part of the currency
                            temp_currency= temp_price(1:j);
                            %the currency is equivalent to the characters of the price that have non-numerical values
                        else
                            flag=true; % when the flag is true it means that we found the begining of the numerical values in the price varible.
                            temp_price=temp_price(j:end);% so the price variable takes only the numerical values.
                        end
                    end
                    features.pricecurrency=temp_currency;
                    features.price=str2double(temp_price);
                end
            end
        end
        
        %Feature 15: Size in MB
        size_MB=char(extractBetween(html_features,'<dd class="information-list__item__definition l-column medium-9 large-6" aria-label="', ' megabytes">'));
        if (isnan(size_MB))  % Validation of the existence of the feature
            size_MB='NaN';
        else
            features.size=str2double(size_MB);
        end
        
        %Feature 16: Last update date (DATE)
        temp_extract=extractBetween(html_features,'<div class="l-row whats-new__content">','<p class="l-column small-6 medium-12 whats-new__latest__version">Version');
        temp_extract = extractBetween(temp_extract,'class="" >','</time>');
        if(~isempty(temp_extract))  % Validation of the existence of the feature
            features.lastupdate = datetime(temp_extract{:});
        else
            features.lastupdate = 'NaN';
        end
        
        %Feature 17: Release date (DATE)
        temp_extract=extractBetween(html_features,',"releaseDate":"','","softwareInfo":{');
        if(~isempty(temp_extract))  % Validation of the existence of the feature
            features.reldate=datetime(temp_extract{:});
        else
            features.reldate='NaN';
        end
        
        %Rating presence control. If there isn't, it will set features as null.
        
        if(~contains(html_features,'<span class="we-customer-ratings__averages__display">'))  % Validation of the existence of the feature
            features.avgcurrat='NaN';
            features.numcurus='NaN';
            features.avgallrat='NaN';
            features.numallus='NaN';
            features.perc5='NaN';
            features.perc4='NaN';
            features.perc3='NaN';
            features.perc2='NaN';
            features.perc1='NaN';
            
        else
            
            %Feature 18: Current version: average user ratings (NO TEXT, ONLY NUMBERS)
            features.avgcurrat=extractBetween(html_features,'{"@type":"AggregateRating","ratingValue":',',"reviewCount"');
            
            %Feature 19: Current version: number of user ratings (INTEGER)
            features.numcurus=extractBetween(html_features,',"reviewCount":','},"offers"');
            
            %Feature 20: Number of user ratings with 5 stars(INTEGER)
            temp_perc=extractBetween(html_features,'bar-graph__stars--5"></span>','</div>');
            features.perc5=extractBetween(temp_perc,'width: ','%;">');
            
            %Feature 21: Number of user ratings with 4 stars(INTEGER)
            temp_perc=extractBetween(html_features,'bar-graph__stars--4"></span>','</div>');
            features.perc4=extractBetween(temp_perc,'width: ','%;">');
            
            %Feature 22: Number of user ratings with 3 stars(INTEGER)
            temp_perc=extractBetween(html_features,'bar-graph__stars--3"></span>','</div>');
            features.perc3=extractBetween(temp_perc,'width: ','%;">');
            
            %Feature 23: Number of user ratings with 2 stars(INTEGER)
            temp_perc=extractBetween(html_features,'bar-graph__stars--2"></span>','</div>');
            features.perc2=extractBetween(temp_perc,'width: ','%;">');
            
            %Feature 24: Number of user ratings with 1 stars(INTEGER)
            temp_perc=extractBetween(html_features,'<span class="we-star-bar-graph__stars "></span>','</div>');
            features.perc1=extractBetween(temp_perc,'width: ','%;">');
        end
        
        %Feature 25: Date Retrieved (set by user)
        features.retdate = date();
        
        if (strcmp(Language,english))
            indx_eng = [indx_eng vect(i)];
            indx_feat = [indx_feat i];
        else
            notEnglish=notEnglish+1; % to know how many apps are not described in English
        end
        AppsFeatures{i,1} = features;
    end
end

merged_post.URL = merged.URL(indx_eng);
merged_post.id = merged.id(indx_eng);
merged_post.name = merged.name(indx_eng);
merged_post.category = merged.category(indx_eng);
AppsFeatures_post = AppsFeatures(indx_feat);

%%
indxMedical = find(strcmp("Medical", [merged_post.category{:}]));
indxHF = find(strcmp("Health and Fitness", [merged_post.category{:}]));
indxBoth = find(strcmp("Both", [merged_post.category{:}]));
% Medical dataset
M_post.URL = merged_post.URL(indxMedical);
M_post.name = merged_post.name(indxMedical);
M_post.id = merged_post.id(indxMedical);
M_post.URL = merged_post.URL(indxBoth);
M_post.name = merged_post.name(indxBoth);
M_post.id = merged_post.id(indxBoth);
% Health and Fitness dataset
HnF_post.URL = merged_post.URL(indxHF);
HnF_post.name = merged_post.name(indxHF);
HnF_post.id = merged_post.id(indxHF);
HnF_post.URL = merged_post.URL(indxBoth);
HnF_post.name = merged_post.name(indxBoth);
HnF_post.id = merged_post.id(indxBoth);

% Saves the results
save('merged.mat', 'merged')
save('M.mat', 'M')
save('HnF.mat', 'HnF')

save('merged_post.mat', 'merged')
save('M_post.mat', 'M')
save('HnF_post.mat', 'HnF')
save('AppsFeatures.mat','AppsFeatures')

% % Exports tables as excel files
% saveAsExcelFile(indxHF,HnF,'health_and_fitness');
% saveAsExcelFile(indxMedical,M,'medical');
% saveAsExcelFile((merged.URL)',merged,'merged');
% saveAsExcelFile((AppsFeatures)',AppsFeatures,'AppsFeatures');