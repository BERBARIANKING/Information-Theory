% Step 1: Define base URL and endpoints
baseURL = 'https://api.hooktheory.com/v1';
authEndpoint = '/users/auth';
trendsEndpoint = '/trends/nodes';

% Step 2: Authentication (POST request to get the HTTP Bearer Token)
username = ''; % Your Hooktheory username
password = ''; % Your Hooktheory password

% Prepare the authentication payload
authPayload = jsonencode(struct('username', username, 'password', password));

% Set the header for the authentication request
authHeaders = {
    'Content-Type', 'application/json';
    'Accept', 'application/json'
};

% Send the POST request for authentication
options = weboptions('HeaderFields', authHeaders, 'MediaType', 'application/json');
try
    response = webwrite([baseURL authEndpoint], authPayload, options);
    % Extract the Bearer Token (activkey) from the response
    activkey = response.activkey; % Response contains the 'activkey'
    fprintf('Authentication successful. Bearer Token: %s\n', activkey);
catch ME
    error('Authentication failed: %s', ME.message);
end

% Step 3: Set up headers for subsequent requests
authHeadersWithToken = {
    'Content-Type', 'application/json';
    'Accept', 'application/json';
    'Authorization', ['Bearer ' activkey]
};
optionsWithAuth = weboptions('HeaderFields', authHeadersWithToken);

% Step 4: Query the API (GET request to the trends endpoint)
try
    trendsData = webread([baseURL trendsEndpoint], optionsWithAuth);
    % Display the response
    disp('Trends Data:');
    disp(trendsData);
catch ME
    error('Failed to retrieve trends data: %s', ME.message);
end
