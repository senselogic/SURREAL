#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "LightSwitch.generated.h"

USTRUCT(BlueprintType)
struct SURREALPROJECT_API FLightConfiguration
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Light Configuration Variables")
    float
        InitialIntensity;

    float
        CurrentIntensity;

    UPROPERTY()
    UObject*
        OwnerObject;
};

UCLASS()
class SURREALPROJECT_API ALightSwitch :
    public AActor
{
    GENERATED_BODY()

    public:

    UCLASS(VisibleAnywhere, Category = "Switch Components")
    class UPointLightComponent*
        PointLightComponent;

    UCLASS(VisibleAnywhere, Category = "Switch Components")
    class USphereComponent*
        SphereComponent;

    ALightSwitch(
         );

    virtual void BeginPlay(
        ) override;

    virtual void Tick(
        float delta_time
        ) override;

    UFUNCTION()
    void OnOverlapBegin(
        class UPrimitiveComponent* overlapped_primitive_component,
        class AActor* other_actor,
        class UPrimitiveComponent* other_primitive_component,
        int32 other_body_index,
        bool is_from_sweep,
        const FHitResult& sweep_hit_result
        );

    UFUNCTION()
    void OnOverlapEnd(
        class UPrimitiveComponent* overlapped_primitive_component = 0,
        class AActor* other_actor = 0,
        class UPrimitiveComponent* other_primitive_component = 0,
        int32 other_body_index = 0
        );

    UFUNCTION()
    void ToggleLight(
        );

    UPROPERTY(VisibleAnywhere, Category = "Switch Variables")
    float
        DesiredIntensity;
};
