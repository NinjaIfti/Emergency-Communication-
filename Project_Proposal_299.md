Project Proposal: Emergency Offline Communication System 

Problem Statement 

Natural disasters such as floods, cyclones, and earthquakes often result in widespread 

communication breakdowns. During these crises, mobile networks and internet services 

become unreliable or completely unavailable, isolating affected individuals and 

communities. This communication failure can delay rescue operations, increase panic, and 

prevent victims from sending emergency alerts or receiving timely help. In Bangladesh and 

many other disaster-prone regions, this lack of connectivity becomes a major obstacle to 

effective disaster response. Therefore, there is a need for a mobile communication system 

that can operate independently of conventional network infrastructure to ensure that people 

can still communicate, share locations, and seek help when traditional systems fail. 

Introduction 

The Emergency Offline Communication System is a proposed Android-based mobile 

application designed to provide communication capabilities without relying on cellular 

networks or the internet. It utilizes Bluetooth and Wi-Fi Direct mesh networking to enable 

peer-to-peer message transmission between nearby devices. This system can help users 

send SOS alerts, GPS locations, and short text updates during emergencies. By forming a 

decentralized network, messages can hop between devices until they reach someone with 

network access or emergency responders, ensuring that no one is left completely 

disconnected. The project is inspired by real-life disasters where victims could not reach 

help due to broken networks. Technologies like mesh networking have already proven 

useful in similar contexts, and this project aims to adapt such technology to the local 

environment with user-friendly design and reliability. The goal is to create a practical 

solution that contributes to community safety, resilience, and disaster management. 

Project Description 

The proposed system will be an Android mobile application capable of establishing an 

offline mesh network using Bluetooth and Wi-Fi Direct APIs. The app will allow users to 

send and receive short text messages and SOS alerts within a network of connected 

devices, even in the absence of mobile data or Wi-Fi connectivity. Each device running the 

app will act as a node in the mesh network. When a user sends a message or alert, it will 

automatically propagate through nearby devices until it reaches its destination or a device 

with internet connectivity. The application will use SQLite for local data storage, ensuring 

messages are stored securely until delivered. The system will include an SOS feature that 

lets users send their GPS coordinates with a single tap. Emergency responders or connected 

users will be able to view these locations on an offline map interface, making rescue 

coordination easier. Security and privacy will be considered through basic encryption of 

transmitted messages. The app will also include a user-friendly interface, designed to work 

efficiently on low-end Android devices, as these are common in developing regions. 

Battery optimization and offline functionality will be prioritized. The ultimate goal is to 

build a lightweight, accessible, and reliable emergency communication tool that empowers 

communities to stay connected in disaster situations. 

Planned Features 

1. Offline Messaging: Send and receive text messages without internet or mobile network. 

2. Mesh Networking: Automatically connects nearby devices using Bluetooth/Wi-Fi Direct 

to create a communication chain.  

3. SOS Alert System: Allows users to send emergency alerts with GPS location 

coordinates.  

4. Offline Location Sharing: Share and receive locations even without internet access. 

5. Local Data Storage: Store messages and logs using SQLite for offline access.  

6. Automatic Message Forwarding: Messages hop between devices to reach intended 

recipients.  

7. Encryption: Basic encryption for message security and privacy.  

8. Battery Optimization: Efficient use of Bluetooth and Wi-Fi to preserve power during 

prolonged use.  

9. User Interface (UI): Simple, responsive interface suitable for non-technical users. 10. 

Testing & Evaluation: Real-world simulation to test performance and message delivery 

range. 

Weekly Breakdown of Project Plan (12 Weeks) 

Week 1: 

Project Research and Requirement Analysis - Study existing offline communication apps 

(Bridgefy, FireChat). - Identify hardware and software requirements. - Define scope and 

limitations. 

Week 2: 

System Design and Architecture - Create system flowcharts and data flow diagrams. - 

Define mesh network model (Bluetooth + Wi-Fi Direct). - Design SQLite database schema 

for message storage. 

Week 3: 

UI/UX Design - Design mockups for login, chat, and SOS pages. - Decide on color 

schemes and layouts. - Review designs with supervisor for feedback. 

Week 4: 

Environment Setup and Initial Coding - Configure Android Studio project. - Integrate 

Bluetooth and Wi-Fi Direct modules. - Set up SQLite database. 

Week 5: 

Offline Messaging Module Development - Implement message sending and receiving 

functions. - Test peer-to-peer message transfer between two devices. 

Week 6: 

Mesh Networking Implementation - Extend communication to multiple nodes. - Test 

message forwarding across 3 to 4 devices. 

Week 7: 

SOS and GPS Integration - Implement location tracking and SOS button. - Ensure 

coordinates can be shared offline. 

Week 8: 

Message Encryption and Data Handling - Add encryption for transmitted messages. - 

Handle message queueing and delivery confirmation. 

Week 9: 

UI Integration and Optimization - Combine backend modules with user interface. - Test 

smooth navigation and low battery usage. 

Week 10: 

Testing and Debugging - Conduct tests under simulated network failure. - Fix connectivity 

and data loss issues. 

Week 11: 

Documentation and Report Preparation - Prepare user manual, technical documentation, 

and screenshots. - Record findings from test results. 

Week 12: 

Final Presentation and Submission - Compile final project report and presentation slides. - 

Demonstrate live working prototype. 

Conclusion 

The Emergency Offline Communication System aims to be a vital tool for disaster 

communication, bridging the gap when conventional systems fail. By using Bluetooth and 

Wi-Fi Direct mesh networking, it ensures that people can still connect, share information, 

and send help requests even in the most challenging situations. The project not only 

strengthens emergency response but also promotes the development of local, low-cost, and 

sustainable technological solutions. With proper implementation, this system can 

contribute significantly to disaster management efforts and community resilience. 
