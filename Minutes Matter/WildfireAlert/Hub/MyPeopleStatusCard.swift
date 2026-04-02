//
//  MyPeopleStatusCard.swift
//  Minutes Matter
//

import SwiftUI

struct MyPeopleStatusCard: View {
    let people: [CaregiverFamilyLink]
    let onSeeAll: () -> Void

    private var displayed: [CaregiverFamilyLink] {
        Array(people.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MY PEOPLE")
                .authSectionLabelStyle()

            ForEach(displayed) { person in
                HStack(alignment: .center, spacing: 12) {
                    Text(person.statusEmoji)
                        .font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(person.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text(person.evacuationLabel)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
            }

            Button(action: onSeeAll) {
                Text("See all →")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .hubCardStyle()
    }
}
