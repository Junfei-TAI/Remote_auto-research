clear;
close all;
clc

rng(1234);
% Parameters
N = 41000; % Number of sets
mean_angle_deg = 0; % Mean misorientation angle in degrees
% std_dev_deg = [2 3 4 5 6 7 8 9 10 11]; % Standard deviation of the misorientation in degrees
std_dev_deg = [5 10 15 20 25 30 35 40 45 50]; % Standard deviation of the misorientation in degrees

for ii = 1:length(std_dev_deg)
    % Step 1: Generate N sets of random ZXZ Euler angles
%     phi = 2 * pi * rand(N, 1); % Z1 rotation
%     theta = pi * rand(N, 1); % X rotation
%     psi = 2 * pi * rand(N, 1); % Z2 rotation
%     euler_angles_random = [phi, theta, psi];
    phi = 2 * pi * zeros(N, 1); % Z1 rotation
    theta = pi * zeros(N, 1); % X rotation
    psi = 2 * pi * zeros(N, 1); % Z2 rotation
    euler_angles_random = [phi, theta, psi];
    % Step 2: Define the reference vector in the global system
    reference_vector = [0, 1, 0]; % y-axis
    
    % Convert angles to radians
    mean_angle_rad = deg2rad(mean_angle_deg);
    std_dev_rad = deg2rad(std_dev_deg(ii));
    
    % Step 3: Generate new vectors with misorientation
    misorientation_angles = mean_angle_rad + std_dev_rad * randn(N, 1); % Normally distributed
    new_vectors = zeros(N, 3);
    
    for i = 1:N
        % Rotate the reference vector by the misorientation angle
        % Around a random axis
        random_axis = randn(1, 3); % Random rotation axis
        random_axis = random_axis / norm(random_axis); % Normalize
        
        % Create a rotation matrix
        rot_vector = axang2rotm([random_axis, misorientation_angles(i)]);
        new_vectors(i, :) = (rot_vector * reference_vector')';
    end
    
    % Normalize the new vectors (optional, but ensures unit vectors)
    new_vectors = new_vectors ./ vecnorm(new_vectors, 2, 2);
    
    % Define the origin for each vector (starting from the origin [0, 0, 0])
    origins = zeros(N, 3);
    
    % Plot the vectors in 3D using quiver3
    figure;
    quiver3(origins(:,1), origins(:,2), origins(:,3), ...
            new_vectors(:,1), new_vectors(:,2), new_vectors(:,3), ...
            'AutoScale', 'on', 'AutoScaleFactor', 0.5, 'LineWidth', 1.5);

    % Set the axes labels and title
    xlabel('X-axis');
    ylabel('Y-axis');
    zlabel('Z-axis');
    xlim([-1,1])
    ylim([-1,1])
    zlim([-1,1])
%     title('3D Plot of New Vectors');
%     axis equal;
    grid on;
    view([0, 0, 1]);
    sname = sprintf('%dSig%d.png', mean_angle_deg, std_dev_deg(ii));
    saveas(gcf, sname);
    % Step 4: Rotate the original random Euler angles to align with the new vectors
    euler_angles_final = zeros(N, 3);
    for i = 1:N
        % Convert the random Euler angles to a rotation matrix
        R_random = eul2rotmZXZ(euler_angles_random(i, :));
        
        % The local z-axis after the initial random rotation
        local_z_axis = (R_random * [0; 0; 1])';
        
        % Find the rotation needed to align the local z-axis with the new vector
        v = cross(local_z_axis, new_vectors(i, :)); % Cross product to find axis of rotation
        s = norm(v); % Magnitude of the vector
        c = dot(local_z_axis, new_vectors(i, :)); % Dot product to find angle cosine
        
        if s ~= 0
            skew_symmetric = [0, -v(3), v(2); v(3), 0, -v(1); -v(2), v(1), 0];
            rot_matrix = eye(3) + skew_symmetric + skew_symmetric^2 * ((1 - c) / s^2);
        else
            rot_matrix = eye(3); % No rotation needed if vectors are aligned
        end
        
        % Convert the alignment rotation matrix back to ZXZ Euler angles
        euler_angles_rotation = rotm2eulZXZ(rot_matrix);
        
        % Combine the original random Euler angles with the rotation
        combined_euler = euler_angles_random(i, :) + euler_angles_rotation;
        
        % Ensure the Euler angles remain within the correct ranges
        combined_euler(1) = mod(combined_euler(1), 2*pi); % Z1 (0 to 2*pi)
        combined_euler(2) = mod(combined_euler(2), pi);   % X (0 to pi)
        combined_euler(3) = mod(combined_euler(3), 2*pi); % Z2 (0 to 2*pi)
        
        euler_angles_final(i, :) = combined_euler;
    end
    
    % Display the final Euler angles
    disp('First few sets of final Euler angles [Z1, X, Z2] in radians:');
    disp(euler_angles_final(1:5, :));
    
    % Convert to degrees if needed
    euler_angles_final_deg = rad2deg(euler_angles_final);
    disp('First few sets of final Euler angles [Z1, X, Z2] in degrees:');
    disp(euler_angles_final_deg(1:5, :));

    filename = sprintf('%dSig%d.mat', mean_angle_deg, std_dev_deg(ii));
    save(filename, 'euler_angles_final_deg');

end

function eulerZXZ = rotm2eulZXZ(R)
    % Calculate the Euler angles from the rotation matrix in ZXZ convention
    
    theta = acos(R(3,3));  % theta is the arccos of the (3,3) element
    
    % Check if theta is close to 0 or pi
    if abs(theta) < 1e-6
        phi = 0;  % Arbitrary value since rotation is about z-axis only
        psi = atan2(R(1,2), R(1,1));  % Rotation is only about the z-axis
    elseif abs(theta - pi) < 1e-6
        phi = 0;  % Arbitrary value since rotation is about z-axis only
        psi = -atan2(R(1,2), R(1,1));  % Rotation is only about the z-axis
    else
        % General case
        phi = atan2(R(1,3), -R(2,3));  % First rotation about Z
        psi = atan2(R(3,1), R(3,2));   % Second rotation about Z
    end
    
    eulerZXZ = [phi, theta, psi];
end

function R = eul2rotmZXZ(euler_angles)
    % euler_angles: [phi, theta, psi] in radians
    phi = euler_angles(1);
    theta = euler_angles(2);
    psi = euler_angles(3);

    % Rotation about Z-axis by phi
    R_Z1 = [cos(phi), -sin(phi), 0;
            sin(phi), cos(phi), 0;
            0, 0, 1];
    
    % Rotation about X-axis by theta
    R_X = [1, 0, 0;
           0, cos(theta), -sin(theta);
           0, sin(theta), cos(theta)];
    
    % Rotation about Z-axis by psi (new Z)
    R_Z2 = [cos(psi), -sin(psi), 0;
            sin(psi), cos(psi), 0;
            0, 0, 1];
    
    % Combined rotation matrix R = R_Z(phi) * R_X(theta) * R_Z(psi)
    R = R_Z1 * R_X * R_Z2;
end